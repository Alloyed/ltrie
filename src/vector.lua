local function try(f, ...)
	local ok, err = pcall(f, ...)
	if not ok then return nil end
	return err
end
local b = bit32 or try(require, 'bit') or error("No bitwise lib found")
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
	shift = 5,
	root = {},
	tail = {},
}

function Vector.from(...)
	local r = EMPTY
	for _, v in ... do
		r = r:conj(v)
	end
	return r
end

function Vector:len()
	return self.count
end
mt.__len = Vector.len

local BITS  = 5
local WIDTH = 32
local MASK  = 31

local function mask(i)
	return b.band(i, MASK)
end

local function tailoff(trie)
	if trie.count < WIDTH then
		return 0
	else
		-- trie.count - 1 is original
		return b.lshift(b.rshift(trie.count - 1, 5), 5)
	end
end

local function arrayFor(trie, idx)
	if not(idx >= 0 and idx < trie.count) then
		error("Index out of bounds")
	end

	if idx >= tailoff(trie) then
		return trie.tail
	end

	local node = trie.root
	local level = trie.shift
	while level > 0 do
		local newidx = mask(b.rshift(idx, level)) + 1
		node = node[newidx]
		level = level - BITS
	end
	return node
end

function Vector:get(idx)
	idx = idx - 1
	local node = arrayFor(self, idx)
	return node[mask(idx) + 1]
end

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
	local subidx = mask(b.rshift(self.count - 1, level)) + 1
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

function Vector:conj(val)
	local idx = self.count
	-- Is there room in the tail?
	if self.count - tailoff(self) < WIDTH then
		newTail = copy(self.tail)
		table.insert(newTail, val)
		return Vec {
			count = self.count + 1,
			shift = self.shift,
			root = self.root,
			tail = newTail
		}
	end

	local newRoot
	local tailNode = copy(self.tail)
	local newShift = self.shift

	-- will root overflow?
	if b.rshift(self.count, 5) > b.lshift(1, self.shift) then
		newRoot = {}
		newRoot[1] = self.root
		newRoot[2] = newPath(self.shift, tailNode)
		newShift = self.shift + 5
	else
		newRoot = pushTail(self, self.shift, self.root, tailNode)
	end

	return Vec {
		count = self.count + 1,
		shift = newShift,
		root = newRoot,
		tail = {val}
	}
end

local function doAssoc(level, node, idx, val)
	local r = copy(node)
	if level == 0 then
		r[mask(idx) + 1] = val
	else
		local subidx = mask(b.rshift(idx, level)) + 1
		r[subidx] = doAssoc(level - BITS, node[subidx], idx, val)
	end
	return r
end

function Vector:assoc(idx, val)
	idx = idx - 1
	if idx == self.count then
		return self:conj(va)
	end
	if not(idx >= 0 and idx < self.count) then
		error("Index out of bounds")
	end
	if idx >= tailoff(self) then
		local newTail = copy(self.tail)
		newTail[mask(idx) + 1] = val
		return Vec {
			count = self.count,
			shift = self.shift,
			root = self.root,
			tail = newTail
		}
	end
	return Vec {
		count = self.count,
		shift = self.shift,
		root = doAssoc(self.shift, self.root, idx, val),
		tail = self.tail
	}
end

return Vector
