-- Naive linked list implementation
local fun = require 'fun'

local Lproto = {}
local list = setmetatable({}, {__index = Lproto})
local mt = {}
list.EMPTY = setmetatable({}, mt) -- Should this be different?

function Lproto:car()
	return rawget(self, '_car')
end

function Lproto:cdr()
	return rawget(self, '_cdr')
end

function Lproto:decons()
	return Lproto.car(self), Lproto.cdr(self)
end

function Lproto:table()
	local tbl = {}
	for _, v in self:ipairs() do
		table.insert(tbl, v)
	end
	return tbl
end

function Lproto:unpack()
	if self == list.EMPTY then
		return
	end
	return list.car(self), Lproto.unpack(list.cdr(self))
end

function list.is_list(o)
	return getmetatable(o) == mt
end

local function _ipairs(param, state)
	if state == list.EMPTY then
		return nil
	end

	local head, tail = list.decons(state)
	if not list.is_list(tail) then
		return list.EMPTY, head, tail
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
function Lproto:ipairs()
	return _ipairs, self, self
end
mt.__ipairs = Lproto.ipairs

mt.__index  = function(self, k)
	if type(k) == 'number' then
		return fun.nth(k, self)
	end
	return Lproto[k]
end

mt.__len = fun.length

-- FIXME
mt.__eq = function(o1, o2)
	return o1:car() == o2:car() and o2:cdr() == o2:cdr()
end

function mt.__tostring(l)
	local head, tail = l:decons()

	if list.is_list(tail) then
		local inner, sep = "", ""
		fun.each(function(v)
			inner = inner .. sep .. tostring(v)
			sep = " "
		end, l)
		return "(" .. inner .. ")"
	end

	return string.format("(%s . %s)", tostring(head), tostring(tail))
end

function list.cons(a, b)
	return setmetatable({_car = a, _cdr = b}, mt)
end

function list.conj(l, a)
	return list.cons(a, l)
end

function Lproto:assoc(k, v)
	local l = self
	local new_l, i = list.cdr(l), 1
	local tmp = {list.car(l)}

	while i ~= k do
		table.insert(tmp, (list.car(new_l)))
		new_l = list.cdr(new_l)
		i = i + 1
	end
	new_l = list.cons(v, new_l)

	for i=#tmp-1, 1, -1 do
		new_l = list.cons(tmp[i], new_l)
	end
	return new_l
end

function Lproto:get(n)
	return fun.nth(n, self)
end

local function reverse(...)
	return fun.reduce(function(l, v)
		return list.cons(v, l)
	end, list.EMPTY, ...)
end

local function from_table(t)
	local l = list.EMPTY
	for i = #t, 1, -1 do
		l = list.cons(t[i], l)
	end
	return l
end

function list.from(...)
	if not fun.nth(1, ...) then
		return list.EMPTY
	elseif list.is_list(...) then
		return ...
	else
		return from_table(fun.totable(...))
	end
end

function list.of(...)
	return list.from({...})
end

return list
