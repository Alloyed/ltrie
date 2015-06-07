--- A subsequence of a vector. Subvecs can only be constructing from an
-- existing, non-transient vector or subvec, and otherwise support everything
-- a normal vector would.
-- @module Subvec

local Vector = require 'ltrie.vector'
local Subvec = {}

local mt = {__index = Subvec, __ipairs = Vector.ipairs}

-- mixins
Subvec.ipairs = Vector.ipairs
Subvec.unpack = Vector.unpack


--- Creates a new subvector `s` containing the elements from `vec` within the
--  range `[vecStart, vecEnd]` such that `s:get(1) == vec:get(vecStart)` and
--  `s:get(s:len()) == vec:get(vecEnd)`
--
--  @param vec the vector
--  @param vecStart the start index of the subvector, inclusive
--  @param vecEnd the end index of the vector, inclusive
--  @usage sv = Subvec.new(Vector.of(1, 2, 3, 4), 2, 4) -- [2, 3, 4]
function Subvec.new(vec, vecStart, vecEnd)
	if getmetatable(vec) == mt then
		vecStart = vecStart + vec.vecStart
		vecEnd = vecEnd + vec.vecEnd
	end
	return setmetatable({
		vec = vec,
		vecStart = vecStart,
		vecEnd = vecEnd
	}, mt)
end

--- Returns the number of elements in the subvector.
--  In lua 5.2 and up, `#subvec` can be used as a shortcut.
--
--  @complexity O(1)
--  @usage sv:len() == 3
function Subvec:len()
	return self.vecEnd - self.vecStart + 1
end

--- Get a value by index. Vector indexes start at one.
--
-- @complexity O(log32 n)
-- @tparam int idx the index
-- @return the value, or `nil` if not found
-- @usage sv:get(2) == 3
function Subvec:get(idx)
	idx = idx - 1 -- s[1] == v[start]
	local subidx = self.vecStart + idx
	if idx < 0 or subidx > self.vecEnd then
		return nil
	end
	return self.vec:get(subidx)
end

--- Returns a new subvector such that `sv:get(idx) == val`. This creates a new
--  parent vector to represent the modification.
-- @complexity O(log32 n)
-- @tparam int idx the index to set
-- @param val the value to set
-- @usage Vector.of(0, 0, 0):assoc(2, 'a') == Vector.of(0, 'a', 0)
function Subvec:assoc(idx, val)
	idx = idx - 1 -- s[1] == v[start]
	local subidx = idx + self.vecStart
	if idx < 0 or subidx > self.vecEnd then
		return error("Index out of bounds")
	elseif subidx == self.vecEnd then
		return self:conj(val)
	end
	return Subvec.new(self.vec:assoc(subidx, val), self.vecStart, self.vecEnd)
end

--- Returns a new subvector with val appended to the end. This creates a new
--  parent vector to represent the modification.
-- @complexity O(log32 n)
-- @param val the value to append
-- @usage sv:conj(5) == Subvec.new(Vector.of(1, 2, 3, 4, 5), 2, 5)
function Subvec:conj(val)
	return Subvec.new(self.vec:assoc(self.vecEnd + 1, val),
	                  self.vecStart, self.vecEnd + 1)
end

--- Returns a new vector with the last value removed.
-- @complexity O(1)
-- @usage Vector.of(1, 2, 3):pop() == Vector.of(1, 2)
function Subvec:pop()
	if self.vecEnd - 1 == self.vecStart then
		return Vector.of()
	end
	return Subvec.new(self.vec, self.vecStart, self.vecEnd - 1)
end

return Subvec
