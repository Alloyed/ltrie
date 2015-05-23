describe("Reducing", function()
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

	it("foldl", function()
		assert.is.equal(15, fun.foldl(function(acc, x)
			return acc + x
		end, 0, fun.range(5)))
		assert.is.equal(15, fun.foldl(fun.operator.add, 0, fun.range(5)))
		assert.is.equal(20, fun.foldl(function(acc, x, y)
			return acc + x * y
		end, 0, fun.zip(fun.range(1, 5), {4, 3, 2, 1})))
		assert.is.equal(fun.reduce, fun.foldl)
	end)

	it("length", function()
		assert.is.equal(5, fun.length {'a', 'b', 'c', 'd', 'e'})
		assert.is.equal(0, fun.length {})
		assert.is.equal(0, fun.length(fun.range(0)))
	end)
	
	it("is_null", function()
		assert.is_false(fun.is_null {'a', 'b', 'c', 'd', 'e'})
		assert.is_true(fun.is_null {})
		assert.is_true(fun.is_null(fun.range(0)))

		reset()
		local gen, init, state = fun.range(5)
		p(fun.is_null(gen, init, state))
		fun.each(p, gen, init, state)
		check {{false}, {1}, {2}, {3}, {4}, {5}}
	end)

	it("is_prefix_of", function()
		assert.is_true(fun.is_prefix_of({'a'}, {'a', 'b', 'c'}))
		assert.is_true(fun.is_prefix_of({}, {'a', 'b', 'c'}))
		assert.is_true(fun.is_prefix_of({}, {}))
		assert.is_false(fun.is_prefix_of({'a'}, {}))
		assert.is_true(fun.is_prefix_of(fun.range(5), fun.range(6)))
		assert.is_false(fun.is_prefix_of(fun.range(6), fun.range(5)))
	end)

	it("all", function()
		assert.is_true(fun.all(function(x) return x end, {true, true, true, true}))
		assert.is_false(fun.all(function(x) return x end, {true, true, true, false}))
		assert.is_true(fun.all(function(x) return x end, {}))
		assert.is.equal(fun.every, fun.all)
	end)

	it("any", function()
		assert.is_false(fun.any(function(x) return x end, {false, false, false, false}))
		assert.is_true(fun.any(function(x) return x end, {false, false, false, true}))
		assert.is_false(fun.any(function(x) return x end, {}))
	end)

	it("sum", function()
		assert.is.equal(15, fun.sum(fun.range(1, 5)))
		assert.is.equal(27, fun.sum(fun.range(1, 5, 0.5)))
		assert.is.equal(0, fun.sum(fun.range(0)))
	end)

	it("product", function()
		assert.is.equal(120, fun.product(fun.range(1, 5)))
		assert.is.equal(7087.5, fun.product(fun.range(1, 5, 0.5)))
		assert.is.equal(1, fun.product(fun.range(0)))
	end)

	it("min", function()
		assert.is.equal(1,   fun.min(fun.range(1, 10, 1)))
		assert.is.equal('c', fun.min {'f', 'd', 'c', 'd', 'e'})
		assert.has.errors(function()
			return min {}
		end)
		assert.is.equal(fun.minimum, fun.min)
	end)

	it("min_by", function()
		local function min_cmp(a, b) if -a < -b then return a else return b end end
		assert.is.equal(10, fun.min_by(min_cmp, fun.range(1, 10, 1)))
		assert.has.errors(function()
			return fun.min_by(min_cmp, {})
		end)
		assert.is.equal(fun.minimum_by, fun.min_by)
	end)

	it("max", function()
		assert.is.equal(10, fun.max(fun.range(1, 10, 1)))
		assert.is.equal('f', fun.max {'f', 'd', 'c', 'd', 'e'})
		assert.has.errors(function()
			return fun.max {}
		end)
		assert.is.equal(fun.maximum, fun.max)
	end)

	it("max_by", function()
		local function max_cmp(a, b) if -a > -b then return a else return b end end
		assert.is.equal(1, fun.max_by(max_cmp, fun.range(1, 10, 1)))
		assert.has.errors(function()
			return fun.max_by(max_cmp, {})
		end)
		assert.is.equal(fun.maximum_by, fun.maximum_by)
	end)
end)
