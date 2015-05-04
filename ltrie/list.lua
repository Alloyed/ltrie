-- Naive linked list implementation
local fun = require 'fun'

local List = {}
local mt = { __index = List }

List.EMPTY = setmetatable({}, mt) -- Should this be different?

function List:car()
	return rawget(self, '_car')
end

function List:cdr()
	return rawget(self, '_cdr')
end

function List:decons()
	return List.car(self), List.cdr(self)
end

function List:table()
	local tbl = {}
	for _, v in self:ipairs() do
		table.insert(tbl, v)
	end
	return tbl
end

function List:unpack()
	if self == List.EMPTY then
		return
	end
	return List.car(self), List.unpack(List.cdr(self))
end

function List.is_list(o)
	return getmetatable(o) == mt
end

local function _ipairs(param, state)
	if state == List.EMPTY then
		return nil
	end

	local head, tail = List.decons(state)
	if not List.is_list(tail) then
		return List.EMPTY, head, tail
	end

	return tail, head
end

--- Implements a stateless, generic for for linked lists.
-- call like
--     for _, v in ipairs(list) do
-- or, in 5.1
--     for _, v in list:ipairs() do
-- note that instead of the first value being a meaningful index like it is
-- in normal ipairs, it is used soley to represent the iterator's state.
-- This is consistent with luafun iterators.
function List:ipairs()
	return _ipairs, self, self
end
mt.__ipairs = List.ipairs

mt.__index = List

mt.__len = fun.length

-- FIXME
mt.__eq = function(o1, o2)
	return o1:car() == o2:car() and o2:cdr() == o2:cdr()
end

function mt.__tostring(l)
	local head, tail = l:decons()

	if List.is_list(tail) then
		local inner, sep = "", ""
		fun.each(function(v)
			inner = inner .. sep .. tostring(v)
			sep = " "
		end, l)
		return "(" .. inner .. ")"
	end

	return string.format("(%s . %s)", tostring(head), tostring(tail))
end

function List.cons(a, b)
	return setmetatable({_car = a, _cdr = b}, mt)
end

function List.conj(l, a)
	return List.cons(a, l)
end

function List:assoc(k, v)
	local l = self
	local new_l, i = List.cdr(l), 1
	local tmp = {List.car(l)}

	while i ~= k do
		table.insert(tmp, (List.car(new_l)))
		new_l = List.cdr(new_l)
		i = i + 1
	end
	new_l = List.cons(v, new_l)

	for i=#tmp-1, 1, -1 do
		new_l = List.cons(tmp[i], new_l)
	end
	return new_l
end

function List:get(n)
	return fun.nth(n, self)
end

local function reverse(...)
	return fun.reduce(function(l, v)
		return List.cons(v, l)
	end, List.EMPTY, ...)
end

local function from_table(t)
	local l = List.EMPTY
	for i = #t, 1, -1 do
		l = List.cons(t[i], l)
	end
	return l
end

function List.from(...)
	if not fun.nth(1, ...) then
		return List.EMPTY
	elseif List.is_list(...) then
		return ...
	else
		return from_table(fun.totable(...))
	end
end

function List.of(...)
	return List.from({...})
end

return List
