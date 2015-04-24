describe("Persistent Vectors", function()
	local Vector = require 'vector'
	local tbl = {}
	for i=1, 2048 do
		table.insert(tbl, 2048 - i)
	end

	local vec
	it("implements from()", function()
		vec = Vector.from(ipairs(tbl))
	end)

	it("implements get()", function()
		for i, v in ipairs(tbl) do
			assert.are.equal(tbl[i], vec:get(i))
		end
	end)

	it("implements len()", function()
		assert.are.equal(#tbl, vec:len())
	end)

	it("implements conj()", function()
		local top = vec:len()
		for _, v in ipairs {'a', 'b', 'c', 'd'} do
			table.insert(tbl, v)
			vec = vec:conj(v)
		end

		for i = top, vec:len() do
			assert.are.equal(tbl[i], vec:get(i))
		end
	end)
	it("implements assoc()", function()
		local l = vec:len()
		local mergeIn = {{l, "TOP"}}
		for i=1, 100 do
			table.insert(mergeIn, {math.random(l), "new#" .. i})
		end
		for _, v in ipairs(mergeIn) do
			local car, cdr = unpack(v)
			tbl[car] = cdr
			vec = vec:assoc(car, cdr)
		end

		for i, v in ipairs(tbl) do
			assert.are.equal(tbl[i], vec:get(i))
		end
	end)
end)
