describe("hashmaps", function()
	local A = require 'ltrie.hash'
	local function totable(new)
		local t = {}
		for _it, k, v in new:pairs() do
			t[k] = v
		end
		return t
	end

	it("implements from()/get()", function()
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

	it("Can hold/delete 2048 random elems #atm", function()
		local ELEMS = 4096
		local tbl = {}
		local full = A.of()
		for i=1, ELEMS do
			tbl[tostring(i)] = i
			full = full:assoc(tostring(i), i)
		end

		local empty = full

		assert(full:get('1929') ~= full:get('1609'))

		local elen = empty:len()
		for k, v in pairs(tbl) do
			assert.are.equal(v, full:get(k))
			empty = empty:dissoc(k)
			elen = elen - 1
			assert.are.equal(elen, empty:len())
		end

		assert.is.equal(empty:len(), 0)
		assert.is.equal(full:len(),  ELEMS)
	end)
	
	it("Implements dissoc()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)

		cmp.c = nil
		assert.is.equal(12, new:get('c'))
		new = new:dissoc('c')
		assert.is.equal(2, new:len())
		assert.is.equal(nil, new:get('c'))
	end)
end)
