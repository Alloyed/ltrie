--- A COW Map using lua's native tables, for testing

local fun = require 'fun'
local AMap = {}
local mt   = { __index = AMap }

local function ctor(data)
	assert(data.table)
	assert(data.count)
	return setmetatable(data, mt)
end

local EMPTY = ctor {table = {}, count = 0}

--- Map from iterator
function AMap.from(...)
	local t = EMPTY
	fun.each(function(k, v)
		t = t:assoc(k, v)
	end, ...)
	return t
end

--- Map from varargs
function AMap.of(...)
	local t = EMPTY
	for i=1, select('#', ...), 2 do
		local k, v = select(i, ...)
		t = t:assoc(k, v)
	end
	return t
end

--- Map from table
function AMap.wrap_table(tbl)
	local i = 0
	for _ in pairs(tbl) do i = i + 1 end
	return ctor { table = tbl, count = i }
end

function AMap:len()
	return self.count
end

local function copy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = v
	end
	return new
end

function AMap:assoc(k, v)
	local newtbl = copy(self.table)
	newtbl[k] = v
	return AMap.wrap_table(newtbl)
end

function AMap:dissoc(k)
	local newtbl = copy(self.table)
	newtbl[k] = nil
	return AMap.wrap_table(newtbl)
end

function AMap:get(k)
	return self.table[k]
end

function AMap:pairs()
	return pairs(self.table)
end

return AMap
