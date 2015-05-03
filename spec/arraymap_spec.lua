describe("arraymap", function()
	local A = require 'ltrie.arraymap'
	it("implements from()/pairs()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)
		assert.are.same(cmp, new.table)
	end)
	it("Implements of()/get()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.of('a', 'a', 'b', 'c', 'c', 12)
		for k, v in pairs(cmp) do
			assert.are.equal(v, new:get(k))
		end
	end)
	it("Implements assoc()/len()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)
		cmp.d = "JEFF"
		new = new:assoc('d', "JEFF")
		assert.is.equal(#cmp, new:len())
		assert.are.same(cmp, new.table)
	end)
	it("Implements dissoc()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)
		cmp.d = "JEFF"
		new = new:assoc('d', "JEFF")
		assert.is.equal(#cmp, new:len())
		assert.are.same(cmp, new.table)
	end)
end)
