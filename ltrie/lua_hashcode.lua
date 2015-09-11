local function try(...)
	local ok, err = pcall(...)
	if not ok then return nil end
	return err
end
local b = bit32 or try(require, 'bit') or error("No bitop lib found")

local hash = {}

local function hashcode(o)
	local t = type(o)
	if t == 'string' then
		local len = #o
		local h = len
		local step = b.rshift(len, 5) + 1

		for i=len, step, -step do
			h = b.bxor(h, b.lshift(h, 5) + b.rshift(h, 2) + string.byte(o, i))
		end
		return h
	elseif t == 'number' then
		local h = math.floor(o)
		if h ~= o then
			h = b.bxor(o * 0xFFFFFFFF)
		end
		while o > 0xFFFFFFFF do
			o = o / 0xFFFFFFFF
			h = b.bxor(h, o)
		end
		return h
	elseif t == 'bool' then
		return t and 1 or 2
	end

	return nil
end

return {
	hashcode = hashcode
}
