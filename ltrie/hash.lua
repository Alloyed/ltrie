--- A Hash Array Mapped Trie, ie. PersistentHashMap in Clojure.
-- For my own sanity, I used <http://git.io/vJeZx> as my model.
-- To match Lua's index-by-one semantics I had to introduce an offset or two.
-- Every line I've done that on is marked with a +1 or -1 comment.

local fun = require 'fun'

local Hash = {}
local mt = { __index = Hash }

local function TODO()
	return error(2, "TODO")
end

local function Hmap(data)
	assert(data.count)
	assert(data.root)
	return setmetatable(data, mt)
end

local function HmapW(data)
	for k, v in pairs(self) do
		if not data[k] then
			data[k] = v
		end
	end
	return Hmap(data)
end

function Hash.from(...)
	local r = Hash.EMPTY
	fun.each(function (k, v)
		r = r:assoc(k, v)
	end, ...)
end

function Hash.of(...)
	local r = Hash.EMPTY
	for i=1, select('#', ...), 2 do
		local k, v = select(i, ...)
		r = r:assoc(k, v)
	end
	return r
end

-- {{{ Nodes
local function implements_node(o)
	assert(o.assoc)
	assert(o.without)
	assert(o.find)
	-- assert(o.iter)
end

local BITS  = 5
local WIDTH = 32
local MASK  = 31

local function mask(hash, shift)
	return b.lshift(1, b.band(b.rshift(hash, shift), MASK))
end

local function popCount() error "TODO" end

local function idxFor(bitmap, bit)
	return popCount(b.band(bitmap, bit - 1)) + 1 -- +1
end

local Node = {} -- {{{
local Node_mt = {__index = Node}

local function NodeC(data)
	assert(data.bitmap)
	assert(data.nodes)
	assert(data.shift)
	return setmetatable(data, Node_mt)
end


function Node.create(shift, leaf, hash, key, val)
	return NodeC {
		bitmap = mask(leaf.hash, shift),
		nodes = {leaf},
		shift = shift
	}:assoc (shift, hash, key, val)
end

local LeafC
function Node:assoc(shift, hash, key, val)
	local bit = mask(hash, shift)
	local idx = index(bit)
	if b.band(bitmap, bit) ~= 0 then
		local n = nodes[idx]:assoc(shift + BITS, hash, key, val)
		if n == nodes[idx] then
			return self
		else
			local newNodes = copy(nodes)
			newNodes[idx] = n
			return NodeC {bitmap = bitmap, nodes = newNodes, shift = shift}
		end
	else
		newNodes = copy(self.nodes)
		newNodes[idx] = LeafC(hash, key, val)
		return NodeC {
			bitmap = b.bor(bitmap, bit), nodes = newNodes, shift = shift
		}
	end
end

function Node:without() error() end
function Node:find() error() end

implements_node(Node) -- }}}

local Leaf = {} -- {{{
local Leaf_mt = {__index = Leaf}
function LeafC(hash, key, val)
	return setmetatable({hash = hash, key = key, val = val}, Leaf_mt)
end

function Leaf:assoc(shift, hash, key, val)
	if hash == self.hash then
		if key == self.key then
			return self
		end
		return CleafC(hash, self, LeafC(hash, key, val))
	end
	return Node.create(shift, self, hash, key, val)
end

function Leaf:without() error() end
function Leaf:find() error() end

implements_node(Leaf) -- }}}

local CLeaf = {} -- {{{
local CLeaf_mt = {}

function CLeafC(hash, leaves)
	return setmetatable({hash = hash, leaves = leaves}, CLeaf_mt)
end

function CLeaf:assoc(shift, hash, key, val)
	if hash == self.hash then
		local idx = idxFor(hash, key)
		if idx then return self end
		local newLeaves = copy(self.leaves)
		table.insert(newLeaves, LeafC(hash, key, val))
		return CleafC(hash, newLeaves)

	end
	return Node.create(shift, self, hash, key, val)
end

function CLeaf:without() error() end
function CLeaf:find() error() end

implements_node(CLeaf) -- }}}

-- }}}

function Hash:assoc(key, val)
	local newRoot = self.root:assoc(0, hashCode(key), key, val)
	if newRoot == root then return self end
	return Hmap{count = self.count + 1, root = newRoot}
end

function Hash:get(key)
	local entry = self.root:find(hashCode(key), key)
	return entry and entry.val
end

function Hash:without(key)
	local newRoot = root.without(hashCode(key), key)
	if newRoot == root then
		return self
	elseif newRoot == nil then
		return Hash.EMPTY
	end
	return Hmap {count = self.count - 1, newRoot}
end

Hash.EMPTY = Hmap {count = 0, root = {
	assoc = function(self, shift, hash, key, val)
		return LeafC(hash, key, val)
	end,
	without = function(self, hash, key)
		return self
	end,
	find = function(...)
		return nil
	end,
	iter = function(...)
		return nil, nil, nil
	end
	}
}

return Hash
