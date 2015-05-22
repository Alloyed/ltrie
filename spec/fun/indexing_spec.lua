describe("indexing", function()
	local fun = require 'ltrie.fun'

	local T = {}
	local function reset()
		T = {}
	end
	local function p(...)
		T[#T+1] = {...}
	end
	local function check(t)
		assert.are.same(T, t)
	end

	it("index", function()
		assert.is.equal(2, fun.index(2, fun.range(5)))

		assert.is_nil(fun.index(10, fun.range(5)))
		assert.is_nil(fun.index(2, fun.range(0)))
		assert.is.equal(2, fun.index('b', {'a', 'b', 'c', 'd', 'e'}))
		assert.is.equal(1, fun.index(1, fun.enumerate{'a', 'b', 'c', 'd', 'e'}))
		assert.is.equal(2, fun.index('b', "abcde"))

		assert.is.equal(fun.index_of, fun.index)
		assert.is.equal(fun.elem_index, fun.index)
	end)

	it("indexes", function()
		reset()
		fun.each(p, fun.indexes('a', {'a', 'b', 'c', 'd', 'e', 'a', 'b', 'c', 'd', 'a', 'a'}))
		check {{1}, {6}, {10}, {11}}

		reset()
		fun.each(p, fun.indexes('f', {'a', 'b', 'c', 'd', 'e', 'a', 'b', 'c', 'd', 'a', 'a'}))
		check {}

		reset()
		fun.each(p, fun.indexes('f', {}))
		check {}

		reset()
		fun.each(p, fun.indexes(1, fun.enumerate{'a', 'b', 'c', 'd', 'e'}))
		check {{1}}

		assert.is.equal(fun.indices, fun.indexes)
		assert.is.equal(fun.elem_indexes, fun.indexes)
		assert.is.equal(fun.elem_indices, fun.indexes)
	end)
end)

