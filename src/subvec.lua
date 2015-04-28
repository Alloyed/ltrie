--- A slice of a vector.
-- @module Subvec
local Vector = require 'vector'
local Subvec = {}

local mt = {__index = Subvec}

function Subvec.new(vec, vecStart, vecEnd)
	if (getmetatable(vec) == mt) then
		vecStart = vecStart + vec.vecStart
		vecEnd = vecEnd + vec.vecEnd
	end
	return setmetatable({
		vec = vec,
		vecStart = vecStart,
		vecEnd = vecEnd
	}, mt)
end

function Subvec:len()
	return self.vecEnd - self.vecStart + 1
end

function Subvec:get(idx)
	idx = idx - 1 -- s[1] == v[start]
	local subidx = self.vecStart + idx
	if idx < 0 or subidx > self.vecEnd then
		return nil
	end
	return self.vec:get(subidx)
end

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

function Subvec:conj(val)
	return Subvec.new(self.vec:assoc(self.vecEnd + 1, val),
	                  self.vecStart, self.vecEnd + 1)
end

function Subvec:pop()
	if self.vecEnd - 1 == self.vecStart then
		return Vector.of()
	end
	return Subvec.new(self.vec, self.vecStart, self.vecEnd - 1)
end

return Subvec
