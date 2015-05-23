--- A naive singly linked list, similar to lisp lists.
--  Like Vector, they are dense, ordered, begin at one, and (at least in this
--  implementation) are immutable.
--  @see Vector
--  @module List

local fun = require 'ltrie.fun'

local List = {}
local mt = { __index = List }

List.EMPTY = setmetatable({}, mt) -- Should this be different?

local function cons(a, b)
	return setmetatable({_car = a, _cdr = b}, mt)
end

local function from_table(t)
	local l = List.EMPTY
	for i = #t, 1, -1 do
		l = cons(t[i], l)
	end
	return l
end

--- Creates a list containing the values provided by the given iterable object.
-- @tparam iterable ... a luafun iterable.
-- @usage List.from({1, 2, 3, 4})
function List.from(...)
	if not fun.nth(1, ...) then
		return List.EMPTY
	elseif List.is_list(...) then
		return ...
	else
		return from_table(fun.totable(...))
	end
end

--- Creates a list containing the arguments.
-- @param ... the values to include
-- @usage List.of(1, 2, 3, 4)
function List.of(...)
	local l = List.EMPTY
	for i=select('#', ...), 1, -1 do
		l = cons((select(i, ...)), l)
	end
	return l
end


--- Check to see if the given object is a list
-- @param o anything
-- @treturn bool true if List, false if not
function List.is_list(o)
	return getmetatable(o) == mt
end


local function car(self)
	return rawget(self, '_car')
end

local function cdr(self)
	return rawget(self, '_cdr')
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

---  @type List

--- Returns the number of values contained by the list.
-- In lua 5.2 and up, `#list` can be used as a shortcut.
-- @complexity O(n)
-- @usage List.of(1, 2, 3):len() == 3
function List:len()
	return fun.length(self)
end
mt.__len = fun.length

--- Iterate through the list, from beginning to end.
--
-- Note that instead of returning `index, value` per iteration like normal
-- `ipairs()`, the value of `index` is implementation-defined.
-- @usage for _it, v in my_list:ipairs() do print(v) end
function List:ipairs()
	return _ipairs, self, self
end
mt.__ipairs = List.ipairs

mt.__eq = function(o1, o2)
	return rawequal(o1, o2) or (car(o1) == car(o2) and cdr(o2) == cdr(o2))
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

--- Returns a new list with the value added to the beginning.
--@complexity O(1)
--@param val the value to add
--@usage List.of(2, 3):conj(1) == List.of(1, 2, 3)
function List:conj(val)
	return List.cons(val, self)
end

--- Returns a new list with the first value removed.
-- @complexity O(1)
-- @usage List.of(1, 2, 3):pop() == List.of(2, 3)
function List:pop()
	return cdr(self)
end

--- Returns a new list with the value at index `idx` replaced with `val`.
-- @complexity O(n)
-- @tparam int idx the index
-- @param val the value
-- @usage List.of(0, 0, 0):assoc(2, 'a') == List.of(0, 'a', 0)
function List:assoc(idx, val)
	local l = self
	local new_l, i = cdr(l), 1
	local tmp = {car(l)}

	while i ~= idx do
		table.insert(tmp, (car(new_l)))
		new_l = cdr(new_l)
		i = i + 1
	end
	new_l = List.cons(val, new_l)

	for i=#tmp-1, 1, -1 do
		new_l = List.cons(tmp[i], new_l)
	end
	return new_l
end

--- Returns the value at index `idx`.
-- @complexity O(n)
-- @tparam int idx the index
-- @return the value, or `nil` if not found.
-- @usage List.of(1, 2, 3):get(2) == 2
function List:get(idx)
	return fun.nth(idx, self)
end

return List
