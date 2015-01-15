local methods = {}

function methods:get()
	return 'TODO'
end

function methods:set()
	return 'TODO'
end

local listMT = { __index = methods }
local function make_list(origin, cap, level, root, tail, ownerID, hash)
	local l = setmetatable({}, listMT)
	l.size = cap - origin
	l._origin = origin
	l._cap = cap
	l._level = level
	l._root = root
	l._ownerID = ownerID
	l._hash = hash
	l._altered = false
	return l
end

local EMPTY_LIST
local function empty_list()
	if not EMPTY_LIST then
		EMPTY_LIST = makeList(0, 0, SHIFT)
	end
	return EMPTY_LIST
end

local function ctor(input)
	return empty_list()
end

return {
	of = ctor
}
