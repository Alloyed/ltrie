--- A persistent vector implementation, modeled after Clojure's
-- PersistentVector. A good blogpost explaining the structure:
--
-- <http://hypirion.com/musings/understanding-persistent-vector-pt-1>
--
-- To match Lua's index-by-one semantics I had to introduce an offset or two.
-- Every line I've done that on is marked with a +1 or -1 comment.
-- @module Vector
--
local function try(...)
	local ok, err = pcall(...)
	if not ok then return nil end
	return err
end
local b = bit32 or try(require, 'bit') or error("No bitop lib found")

local BITS  = 5
local WIDTH = 32
local MASK  = 31

local Vector = {}

local mt = {
	__index = Vector,
}

local function Vec(data)
	assert(data.count)
	assert(data.shift)
	assert(data.root)
	assert(data.tail)
	return setmetatable(data, mt)
end

local function VecW(self, data)
	for k, v in pairs(self) do
		if not data[k] then
			data[k] = v
		end
	end
	return Vec(data)
end

local EMPTY = Vec {
	count = 0,
	shift = BITS,
	root  = {},
	tail  = {},
}

--- Creates a vector containing the elements provided by the given iterator.
-- @param ... the iterator
-- @usage Vector.from(ipairs {1, 2, 3, 4})
function Vector.from(...)
	local r = EMPTY
	for _, v in ... do
		r = r:conj(v)
	end
	return r
end

--- Creates a vector containing the arguments.
-- @param ... the arguments to include
-- @usage Vector.of(1, 2, 3, 4)
function Vector.of(...)
	local r =  EMPTY
	for i=1, select('#', ...) do
		r = r:conj(selec(i, ...))
	end
	return r
end

--- @type Vector

--- Returns the number of elements contained in the vector.
-- In lua 5.2 and up, `#vector` can be used as a shortcut.
function Vector:len()
	return self.count
end
mt.__len = Vector.len

local function mask(i)
	return b.band(i, MASK)
end

local function tailoff(trie)
	if trie.count < WIDTH then
		return 0
	else
		local last_idx = trie.count - 1
		return b.lshift(b.rshift(last_idx, BITS), BITS)
	end
end

local OOB = {}

local function arrayFor(trie, idx)
	if not(idx >= 0 and idx < trie.count) then
		return OOB
	end

	if idx >= tailoff(trie) then
		return trie.tail
	end

	local node = trie.root
	local level = trie.shift
	while level > 0 do
		local newidx = mask(b.rshift(idx, level)) + 1 -- +1
		node = node[newidx]
		level = level - BITS
	end
	return node
end

--- Returns the value stored at `idx`, or `nil` otherwise.
-- @tparam int idx the index
function Vector:get(idx)
	idx = idx - 1 -- -1
	local node = arrayFor(self, idx)
	if node == OOB then return nil end
	return node[mask(idx) + 1] -- +1
end
-- mt.__index = Vector.get

local function iter(param, state)
	local vec, idx = param, state
	idx = idx + 1
	local val = vec:get(idx)
	if val then
		return idx, val
	end
end
function Vector:ipairs()
	return iter, self, 0
end
mt.__ipairs = Vector.ipairs

local function newPath(level, node)
	if level == 0 then
		return node
	end
	local r = {}
	r[1] = newPath(level - BITS, node)
	return r
end

local function copy(tbl)
	return {unpack(tbl)}
end

local function pushTail(self, level, parent, tailNode)
	local subidx = mask(b.rshift(self.count - 1, level)) + 1 -- +1
	local r = copy(parent)

	local nodeToInsert
	if level == BITS then       -- is parent leaf?
		nodeToInsert = tailNode
	elseif parent[subidx] then -- does tailNode map to an existing child?
		nodeToInsert = pushTail(self, level - BITS, parent[subidx], tailNode)
	else
		nodeToInsert = newPath(level - BITS, tailNode)
	end

	r[subidx] = nodeToInsert
	return r
end

--- Returns a new vector with val appended to the end.
-- @param val the value to append
function Vector:conj(val)
	local idx = self.count
	-- Is there room in the tail?
	if self.count - tailoff(self) < WIDTH then
		newTail = copy(self.tail)
		table.insert(newTail, val)
		return VecW(self, {
			count = self.count + 1,
			tail = newTail
		})
	end

	local newRoot
	local tailNode = copy(self.tail)
	local newShift = self.shift

	-- will root overflow?
	if b.rshift(self.count, BITS) > b.lshift(1, self.shift) then
		newRoot = {}
		newRoot[1] = self.root
		newRoot[2] = newPath(self.shift, tailNode)
		newShift = self.shift + BITS
	else
		newRoot = pushTail(self, self.shift, self.root, tailNode)
	end

	return VecW(self, {
		count = self.count + 1,
		shift = newShift,
		root = newRoot,
		tail = {val}
	})
end

local function doAssoc(level, node, idx, val)
	local r = copy(node)
	if level == 0 then
		r[mask(idx) + 1] = val -- +1
	else
		local subidx = mask(b.rshift(idx, level)) + 1 -- +1
		r[subidx] = doAssoc(level - BITS, node[subidx], idx, val)
	end
	return r
end

--- Returns a new vector such that `vector:get(idx) == val`
-- @tparam int idx the index to set.
-- @param val the value to set
function Vector:assoc(idx, val)
	idx = idx - 1 -- -1
	if idx == self.count then
		return self:conj(va)
	end
	if not(idx >= 0 and idx < self.count) then
		error("Index out of bounds")
	end
	if idx >= tailoff(self) then
		local newTail = copy(self.tail)
		newTail[mask(idx) + 1] = val -- +1
		return VecW(self, {
			tail = newTail
		})
	end
	return VecW(self, {
		root = doAssoc(self.shift, self.root, idx, val),
	})
end

local function popTail(level, node)
	local subidx = mask(b.rshift(self.count - 2, level)) + 1  -- +1
	if level > BITS then
		local newChild = popTail(level - BITS, node[subidx])
		if newChild == nil and subidx == 1 then
			return nil
		else
			local r = copy(node)
			r[subidx] = newChild
			return r
		end
	elseif subidx == 1 then
		return nil
	else
		local r = copy(node)
		r[subidx] = nil
		return r
	end
end

--- Returns a new vector with the last element removed. Yes, I know
-- that's not the traditional definition of pop(), but it's the name clojure
-- uses.
function Vector:pop()
	if self.count == 0 then
		return error("Can't pop from empty vector")
	elseif self.count == 1 then
		return EMPTY
	elseif self.count - tailoff(self) > 1 then
		local newTail = copy(self.tail)
		table.remove(newTail)
		return VecW(self, {
			count = self.count - 1,
			tail  = newTail
		})
	end

	local newTail = arrayFor(self, self.count - 2)
	local newRoot = popTail(shift, root)
	local newShift = shift
	if newRoot == nil then
		newRoot = EMPTY_NODE
	elseif self.shift > BITS and newRoot[2] == nil then
		newRoot = newRoot[1]
		newShift = newShift - 1
	end

	return Vec {
		count = self.count - 1,
		shift = newShift,
		root  = newRoot,
		tail  = newTail
	}
end

return Vector
