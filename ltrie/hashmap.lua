--- An immutable hashmap, modelled after PersistentHashMap in Clojure.
--  Hashmaps much like lua tables in that they map keys to values:
--
--  	local my_map = Hashmap.from { foo = 'bar', [2] = 'baz' }
--  	print(my_map:get('foo')) -- 'bar'
--
--  But because they are persistent, modifications create a new Hashmap instead
--  of changing the old one:
--
--  	local my_new_map = my_map:assoc('foo', 42)
--  	print(my_new_map:get('foo')) -- 42
--  	print(my_map:get('foo')) -- still 'bar'
--
--  It is internally implemented as a Hash Array Mapped Trie (HAMT), which you
--  can learn more about from the [Wikipedia article][1].
--
--  [1]: https://en.wikipedia.org/wiki/Hash_array_mapped_trie
--
--  @module Hashmap
--

-- Implementation Details:
-- =======================
-- For my own sanity, I used <http://git.io/vJeZx> as my model.
-- To match Lua's index-by-one semantics I had to introduce an offset or two.
-- Every line I've done that on is marked with a +1 or -1 comment.

local function try(...)
	local ok, err = pcall(...)
	if not ok then return nil end
	return err
end
local fun = require 'ltrie.fun'
local b = bit32 or try(require, 'bit') or error("No bitop lib found")
local hashcode = require 'hashcode'.hashcode

local Hash = {}
local mt = { __index = Hash }

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
	return r
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

-- popcount for 32bit integers {{{
local m1  = 0x55555555
local m2  = 0x33333333
local m4  = 0x0f0f0f0f
local h01 = 0x01010101
local function popCount(x)
	x = x - b.band(b.rshift(x, 1), m1)
	x = b.band(x, m2) + b.band(b.rshift(x, 2), m2)
	x = b.band(x + b.rshift(x, 4), m4)
	x = x + b.rshift(x, 8)
	x = x + b.rshift(x, 16)
	return b.band(x, 0x7f)
end
-- }}}

local function idxFor(bitmap, bit)
	local r = popCount(b.band(bitmap, bit - 1)) + 1
	return r
end

local Node = {} -- {{{
local Node_mt = { name = "Node.", __index = Node}

local function NodeC(data)
	assert(data.bitmap, "no bitmap")
	assert(data.nodes, "no nodes")
	assert(data.shift, "no shift")
	return setmetatable(data, Node_mt)
end


function Node.create(shift, leaf, hash, key, val)
	return NodeC {
		bitmap = mask(leaf.hash, shift),
		nodes = {leaf},
		shift = shift
	}:assoc (shift, hash, key, val)
end

local function copy(tbl)
	local t = {}
	for k, v in pairs(tbl) do
		t[k] = v
	end
	return t
end

local LeafC
function Node:assoc(shift, hash, key, val)
	local bit = mask(hash, shift)
	local idx = idxFor(self.bitmap, bit)
	if b.band(self.bitmap, bit) ~= 0 then -- collision
		local n, upd = self.nodes[idx]:assoc(shift + BITS, hash, key, val)
		if n == self.nodes[idx] then
			return self, upd
		else
			local newNodes = copy(self.nodes)
			newNodes[idx] = n
			return NodeC {
				bitmap = self.bitmap,
				nodes  = newNodes,
				shift  = shift
			}, upd
		end
	else
		newNodes = copy(self.nodes)
		-- Shift forward old nodes
		for i=#self.nodes, idx, -1 do
			newNodes[i+1] = newNodes[i]
		end
		newNodes[idx] = LeafC(hash, key, val)
		return NodeC {
			bitmap = b.bor(self.bitmap, bit),
			nodes  = newNodes,
			shift  = shift
		}
	end
end

function Node:without(hash, key)

	local bit = mask(hash, self.shift)
	if b.band(self.bitmap, bit) == 0 then
		return self
	end

	local idx = idxFor(self.bitmap, bit)
	local N = self.nodes[idx]
	local n = N and N:without(hash, key)

	if n == N then
		return self
	end

	if n == nil then
		if self.bitmap == bit then
			return nil
		end
		local newNodes = copy(self.nodes)
		for i=idx, #self.nodes do
			newNodes[i] = newNodes[i+1]
		end
		return NodeC {
			bitmap = b.band(self.bitmap, b.bnot(bit)),
			nodes = newNodes,
			shift = self.shift
		}
	end

	local newNodes = copy(self.nodes)
	newNodes[idx] = n
	return NodeC {
		bitmap = self.bitmap,
		nodes = newNodes,
		shift = self.shift
	}
end

function Node:find(hash, key)
	local bit = mask(hash, self.shift)
	if b.band(self.bitmap, bit) ~= 0 then
		local idx = idxFor(self.bitmap, bit)
		local node = self.nodes[idx]
		return node:find(hash, key)
	end
	return nil
end

local function node_iter(self, state)
	if not state.state then
		local leaf
		state.it, leaf = next(self.nodes, state.it)

		if leaf == nil then return nil end
		state.gen, state.param, state.state = leaf:iter()
	end

	local inner_state, k, v = state.gen(state.param, state.state)
	state.state = inner_state
	if inner_state == nil then
		return nested_iter(self, inner_state)
	end

	return state, k, v
end

function Node:iter()
	return node_iter, self, {it = nil}
end

implements_node(Node) -- }}}

local Leaf = {} -- {{{
local Leaf_mt = { name="K/V leaf", __index = Leaf}
function LeafC(hash, key, val)
	return setmetatable({hash = hash, key = key, val = val}, Leaf_mt)
end

local CLeafC
function Leaf:assoc(shift, hash, key, val)
	if hash == self.hash then
		if key == self.key then
			if val == self.val then
				return self
			else
				return LeafC(hash, key, val), true
			end
		end
		return CLeafC(hash, {self, LeafC(hash, key, val)})
	end
	return Node.create(shift, self, hash, key, val)
end

function Leaf:without(hash, key)
	if hash == self.hash and key == self.key then
		return nil
	end
	return self
end

function Leaf:find(hash, key)
	if hash == self.hash and key == self.key then
		return self
	end
	return nil
end

local function leaf_it(self, state)
	if state then
		return false, self.key, self.val
	end
	return nil
end

function Leaf:iter()
	return leaf_it, self, true
end

implements_node(Leaf) -- }}}

local CLeaf = {} -- {{{
local CLeaf_mt = { name="Collision leaf", __index = CLeaf }

function CLeafC(hash, leaves)
	return setmetatable({hash = hash, leaves = leaves}, CLeaf_mt)
end

function CLeaf:assoc(shift, hash, key, val)
	if hash == self.hash then
		local idx = findIdx(self.leaves, hash, key)
		if idx ~= -1 then
			return self:assoc(shift, hash, key, val)
		end
		local newLeaves = copy(self.leaves)
		table.insert(newLeaves, LeafC(hash, key, val))
		return CLeafC(hash, newLeaves)
	end
	return Node.create(shift, self, hash, key, val)
end

function CLeaf:without(hash, key)
	local idx = findIdx(self.leaves, hash, key)
	if idx == -1 then
		return self
	end

	local len = #self.leaves
	if len == 2 then
		if idx == 1 then
			return self.leaves[2]
		else
			return self.leaves[1]
		end
	end

	local newLeaves = copy(self.leaves)
	for i=idx, len do
		newLeaves[i] = newLeaves[i + 1]
	end

	return CLeafC(hash, newLeaves)
end

function CLeaf:find(hash, key)
	local idx = findIdx(self.leaves, hash, key)
	if idx == -1 then
		return nil
	end
	return self.leaves[idx]
end

local function nested_iter(self, state)
	if not state.state then
		state.i = state.i + 1
		local leaf = self.leaves[state.i]
		if leaf == nil then return nil end
		state.gen, state.param, state.state = leaf:iter()
	end

	local inner_state, k, v = state.gen(state.param, state.state)
	state.state = inner_state
	if inner_state == nil then
		return nested_iter(self, inner_state)
	end

	return state, k, v
end

function CLeaf:iter()
	return nested_iter, self, {i = 0}
end

function findIdx(leaves, hash, key)
	for i, v in ipairs(leaves) do
		if v:find(hash, key) ~= nil then
			return i
		end
	end
	return -1
end

implements_node(CLeaf) -- }}}

-- }}}

function Hash:len()
	return self.count
end
mt.__len = Hash.len

function Hash:assoc(key, val)
	local newRoot, isUpdate = self.root:assoc(0, hashcode(key), key, val)
	if newRoot == self.root then 
		return self
	end
	local newCount = self.count + (isUpdate and 0 or 1)
	local r = Hmap {count = newCount, root = newRoot}
	assert(r:get(key) == val)
	return r
end

function Hash:get(key)
	local entry = self.root:find(hashcode(key), key)
	return entry and entry.val
end

function Hash:dissoc(key)
	local hc = hashcode(key)
	local newRoot = self.root:without(hc, key)
	if newRoot == self.root then
		assert(self.root:find(hc, key) == nil)
		return self
	elseif newRoot == nil then
		return Hash.EMPTY
	end
	assert(newRoot:find(hc, key) == nil)
	return Hmap {count = self.count - 1, root = newRoot}
end

function Hash:ipairs()
	return self.root:iter()
end
mt.__ipairs = Hash.ipairs

function Hash:pairs()
	local gen, param, state = self.root:iter()
	local function iter()
		-- since we use the same mutable state table we can ignore _it
		local _it, k, v = gen(param, state)
		return k, v
	end

	return iter, param, state
end
mt.__pairs = Hash.pairs

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
