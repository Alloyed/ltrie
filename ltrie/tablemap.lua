--- A COW Map using lua's native tables, for testing

local fun = require 'ltrie.fun'
local TMap = {}
local mt   = { __index = TMap }

local function ctor(data)
	assert(data.table)
	assert(data.count)
	return setmetatable(data, mt)
end

local EMPTY = ctor {table = {}, count = 0}

--- Map from iterator
function TMap.from(...)
	local t = EMPTY
	fun.each(function(k, v)
		t = t:assoc(k, v)
	end, ...)
	return t
end

--- Map from varargs
function TMap.of(...)
	local t = EMPTY
	for i=1, select('#', ...), 2 do
		local k, v = select(i, ...)
		t = t:assoc(k, v)
	end
	return t
end

--- Map from table
function TMap.wrap_table(tbl)
	local i = 0
	for _ in pairs(tbl) do i = i + 1 end
	return ctor { table = tbl, count = i }
end

function TMap:len()
	return self.count
end

local function copy(tbl)
	local new = {}
	for k, v in pairs(tbl) do
		new[k] = v
	end
	return new
end

function TMap:assoc(k, v)
	local newtbl = copy(self.table)
	newtbl[k] = v
	return TMap.wrap_table(newtbl)
end

function TMap:dissoc(k)
	local newtbl = copy(self.table)
	newtbl[k] = nil
	return TMap.wrap_table(newtbl)
end

function TMap:get(k)
	return self.table[k]
end

function TMap:pairs()
	return pairs(self.table)
end

return TMap
