--- An immutable vector datatype, modeled after Clojure's PersistentVector.
--  It can be used to store sequential data, much like Lua tables:
--
--  	local my_vector = Vector.from('a', 'b', 'c')
--  	print(my_vector:get(2)) -- 'c'
--
--  But because they are persistent, modifications create a new vector instead
--  of changing the old one:
--
--  	local my_new_vector = my_vector:set(2, 'd')
--  	print(my_new_vector:get(2)) -- 'd'
--  	print(my_vector:get(2))     -- still 'c'
--
--  Vectors are dense, ordered, and indexed-by-one, meaning a vector will never
--  have an element whose index doesn't fall in between `[1 .. v:len()]`.
--
--  `nil` is a valid element, however, so a vector like:
--
--  	Vector.of(1, nil, nil, 4)
--
--  has a size of four, and iterating through it
--  will include the nil values.
--
--  @module Vector

-- Implementation Notes
-- ====================
--
-- A good blogpost explaining the structure's implementation:
--
-- <http://hypirion.com/musings/understanding-persistent-vector-pt-1>
--
-- My reference code was this particular commit:
--
-- <http://git.io/vT7zG>
--
-- To match Lua's index-by-one semantics I had to introduce an offset or two.
-- Every line I've done that on is marked with a +1 or -1 comment.

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

local EMPTY = Vec {
	count = 0,
	shift = BITS,
	root  = {},
	tail  = {},
}

--- Creates a vector containing the elements provided by the given iterator.
-- @tparam iterator genparamstate the iterator
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
		r = r:conj(select(i, ...))
	end
	return r
end

--- Checks to see if given object is a vector.
-- @param o anything
-- @treturn bool `true` if List, false if not
function Vector.is_vector(o)
	return getmetatable(o) == mt
end

--- @type Vector

--- Returns the number of elements contained in the vector.
-- In lua 5.2 and up, `#vector` can be used as a shortcut.
--
-- @complexity O(1)
-- @usage Vector.of(1, 2, 3):len() == 3
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

--- Get a value by index. Vector indexes start at one.
--
-- @complexity O(log32 n)
-- @tparam int idx the index
-- @return the value, or `nil` if not found
-- @usage Vector.of(1, 2, 3):get(1) == 1
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

--- Iterate through the vector, from beginning to end.
--
-- Note that instead of returning `index, value` per iteration like normal
-- `ipairs()`, the value of `index` is implementation-defined.
-- @usage for _it, v in my_vector:ipairs() do print(v) end
function Vector:ipairs()
	return iter, self, 0
end
mt.__ipairs = Vector.ipairs

function Vector:unpack()
	local l = self:len()
	local function loop(i)
		if i >= len then
			return self:get(i)
		end
		return self:get(i), loop(i+1)
	end

	return loop(1)
end

local function newPath(level, node)
	if level == 0 then
		return node
	end
	local r = {}
	r[1] = newPath(level - BITS, node)
	return r
end

local function copy(owner, tbl)
	local set_dirty = false
	if owner._mutate then
		if tbl._mutate == owner._mutate then
			return tbl
		else
			set_dirty = true
		end
	end

	local t = {}
	local mt = getmetatable(tbl)
	for k, v in pairs(tbl) do
		t[k] = v
	end

	if set_dirty then
		t._mutate = owner._mutate
	end
	return setmetatable(t, mt)
end

local function pushTail(self, level, parent, tailNode)
	local subidx = mask(b.rshift(self.count - 1, level)) + 1 -- +1
	local r = copy(self, parent)

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
-- @complexity O(1)
-- @param val the value to append
-- @usage Vector.of(1, 2):conj(3) == Vector.of(1, 2, 3)
function Vector:conj(val)
	local idx = self.count
	-- Is there room in the tail?
	if self.count - tailoff(self) < WIDTH then
		local newTail = copy(self, self.tail)
		table.insert(newTail, val)

		local r = copy(self, self)

		r.count = self.count + 1
		r.tail = newTail

		return r
	end

	local newRoot
	local tailNode = copy(self, self.tail)
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

	local r = copy(self, self)

	r.count = self.count + 1
	r.shift = newShift
	r.root  = newRoot
	r.tail  = {val}

	return r
end

local function doAssoc(self, level, node, idx, val)
	local r = copy(self, node)
	if level == 0 then
		r[mask(idx) + 1] = val -- +1
	else
		local subidx = mask(b.rshift(idx, level)) + 1 -- +1
		r[subidx] = doAssoc(self, level - BITS, node[subidx], idx, val)
	end
	return r
end

--- Returns a new vector such that `vector:get(idx) == val`
-- @complexity O(log32 n)
-- @tparam int idx the index to set
-- @param val the value to set
-- @usage Vector.of(0, 0, 0):assoc(2, 'a') == Vector.of(0, 'a', 0)
function Vector:assoc(idx, val)
	idx = idx - 1 -- -1
	if idx == self.count then
		return self:conj(va)
	end
	if not(idx >= 0 and idx < self.count) then
		error("Index out of bounds")
	end
	if idx >= tailoff(self) then
		local newTail = copy(self, self.tail)
		newTail[mask(idx) + 1] = val -- +1
		local r = copy(self, self)
		r.tail = newTail
		return r
	end
	local r = copy(self, self)
	r.root = doAssoc(self, self.shift, self.root, idx, val)

	return r
end

local function popTail(level, node)
	local subidx = mask(b.rshift(self.count - 2, level)) + 1  -- +1
	if level > BITS then
		local newChild = popTail(level - BITS, node[subidx])
		if newChild == nil and subidx == 1 then
			return nil
		else
			local r = copy(self, node)
			r[subidx] = newChild
			return r
		end
	elseif subidx == 1 then
		return nil
	else
		local r = copy(self, node)
		r[subidx] = nil
		return r
	end
end

--- Returns a new vector with the last value removed.
-- @complexity O(1)
-- @usage Vector.of(1, 2, 3):pop() == Vector.of(1, 2)
function Vector:pop()
	if self.count == 0 then
		return error("Can't pop from empty vector")
	elseif self.count == 1 then
		return EMPTY
	elseif self.count - tailoff(self) > 1 then
		local newTail = copy(self, self.tail)
		table.remove(newTail)
		local r = copy(self, self)
		r.count = self.count - 1
		r.tail = newTail

		return r
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

	local r = copy(self,self)
	r.count = self.count - 1
	r.shift = newShift
	r.root  = newRoot
	r.tail  = newTail
	return r
end

function Vector:withMutations(fn)
	local mut = copy({_mutate = {}}, self)
	local immut = fn(mut)
	immut._mutate = nil -- doesn't count~
	return immut
end

return Vector
