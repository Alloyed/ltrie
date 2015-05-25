describe("hashmaps", function()
	local A = require 'ltrie.hashmap'
	local function totable(new)
		local t = {}
		for k, v in new:pairs() do
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

	it("implements of()/pairs()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.of('a', 'a', 'b', 'c', 'c', 12)

		for k, v in new:pairs() do
			assert.are.equal(v, cmp[k])
		end
	end)

	it("implements assoc()/len()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)

		assert.is.equal(3, new:len())
		cmp.d = "JEFF"
		new = new:assoc('d', "JEFF")
		assert.is.equal(4, new:len())

		assert.are.same(cmp, totable(new))
	end)

	it("can overwrite existing values using assoc() #atm", function()
		local t = A.from { a = 1 }

		assert.is.equal(1, t:get('a'))
		assert.is.equal(1, t:len())

		t = t:assoc('a', 1)
		assert.is.equal(1, t:get('a'))
		assert.is.equal(1, t:len())

		t = t:assoc('a', 4)
		assert.is.equal(4, t:get('a'))
		assert.is.equal(1, t:len())


		t = A.from {a = 1, b = 2, c = 3}

		assert.is.equal(1, t:get('a'))
		assert.is.equal(3, t:len())

		t = t:assoc('a', 1)
		assert.is.equal(1, t:get('a'))
		assert.is.equal(3, t:len())

		t = t:assoc('a', 4)
		assert.is.equal(4, t:get('a'))
		assert.is.equal(3, t:len())
	end)

	it("can hold/delete 2048 elems", function()
		local ELEMS = 4096
		local tbl = {}
		local full = A.of()
		for i=1, ELEMS do
			tbl[tostring(i)] = i
			full = full:assoc(tostring(i), i)
		end

		local empty = full

		assert.are_not.equal(full:get('1929'), full:get('1609'))

		local elen = empty:len()
		for k, v in pairs(tbl) do
			assert.are.equal(v, empty:get(k))
			empty = empty:dissoc(k)
			assert.are.equal(nil, empty:get(k))
			elen = elen - 1
			assert.are.equal(elen, empty:len())
		end

		assert.is.equal(empty:len(), 0)
		assert.is.equal(full:len(),  ELEMS)
	end)
	
	it("implements dissoc()", function()
		local cmp = { a = 'a', b = 'c', c = 12 }
		local new = A.from(cmp)

		cmp.c = nil
		assert.is.equal(12, new:get('c'))
		new = new:dissoc('c')
		assert.is.equal(2, new:len())
		assert.is.equal(nil, new:get('c'))
	end)
end)
