describe("hashmaps", function()
	local A = require 'ltrie.hash'
	local function totable(new)
		local t = {}
		for _it, k, v in new:pairs() do
			t[k] = v
		end
		return t
	end

	it("implements from()/get() #atm", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)

		for k, v in pairs(cmp) do
			assert.are.equal(v, new:get(k))
		end

		cmp.a = 'b'
		assert.are_not.equal(new:get('a'), cmp.a)
	end)

	it("Implements of()/pairs()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.of('a', 'a', 'b', 'c', 'c', 12)

		for _it, k, v in new:pairs() do
			assert.are.equal(v, cmp[k])
		end
	end)

	it("Implements assoc()/len()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)

		assert.is.equal(3, new:len())
		cmp.d = "JEFF"
		new = new:assoc('d', "JEFF")
		assert.is.equal(4, new:len())

		assert.are.same(cmp, totable(new))
	end)
	
	it("Implements dissoc()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)

		cmp.c = nil
		new = new:dissoc('c')

		assert.is.equal(2, new:len())
		assert.are.same(cmp, new.table)
	end)

end)
