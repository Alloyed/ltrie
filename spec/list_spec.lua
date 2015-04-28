describe("list", function()
	local fun  = require 'fun'
	local list = require 'list'

	it("implements (from)", function()
		assert.are.same(
			list.from{1, 2, 3},
			list.cons(1, list.cons(2, list.cons(3, nil))))
	end)
	it("implements (get)", function()
		assert.is.equal(list.get(list.from{6, 7, 8}, 2), 7)
	end)
	it("implements (conj)", function()
		assert.are.same(
			fun.totable(list.conj(list.from{2, 3, 4}, 1)),
			{1, 2, 3, 4})
	end)
	it("implements (assoc)", function()
		local old = list.from{1, 2, 3, 4}
		assert.are.same(
			fun.totable(list.assoc(old, 1, 10)),
			{10, 2, 3, 4})
		assert.are.same(
			fun.totable(list.assoc(old, 3, 10)),
			{1, 2, 10, 4})
		assert.are.same(
			fun.totable(old),
			{1, 2, 3, 4})
	end)
end)
