describe("Slicing", function()
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

	it("nth", function()
		assert.is.equal(2, fun.nth(2, fun.range(5)))
		assert.is_nil(fun.nth(10, fun.range(5)))
		assert.is_nil(fun.nth(2, fun.range(0)))
		assert.is.equal('b', fun.nth(2, {'a', 'b', 'c', 'd', 'e'}))
		assert.are.same({2, 'b'}, {fun.nth(2, fun.enumerate {'a', 'b', 'c', 'd', 'e'})})
		assert.is.equal('b', fun.nth(2, "abcdef"))
	end)

	it("head", function()
		assert.is.equal('a', fun.head {'a', 'b', 'c', 'd', 'e'})
		assert.has_errors(function()
			return fun.head {}
		end)
		assert.has_errors(function()
			return fun.head(fun.range())
		end)
		assert.are.same({1, 'a'}, {fun.head(fun.enumerate {'a', 'b'})})

		assert.is.equal(fun.car, fun.head)
	end)

	it('tail', function()
		reset()
		fun.each(p, fun.tail {'a', 'b', 'c', 'd', 'e'})
		check {{'b'}, {'c'}, {'d'}, {'e'}}

		reset()
		fun.each(p, fun.tail {})
		check {}

		reset()
		fun.each(p, fun.tail(fun.range(0)))
		check {}

		reset()
		fun.each(p, fun.tail(fun.enumerate {'a', 'b'}))
		check {{2, 'b'}}

		assert.is.equal(fun.cdr, fun.tail)
	end)

	it('take_n', function()
		reset()
		fun.each(p, fun.take_n(0, fun.duplicate(48)))
		check {}

		reset()
		fun.each(p, fun.take_n(5, fun.range(0)))
		check {}

		reset()
		fun.each(p, fun.take_n(1, fun.duplicate(48)))
		check {{48}}

		reset()
		fun.each(p, fun.take_n(5, fun.duplicate(48)))
		check {{48}, {48}, {48}, {48}, {48}}

		reset()
		fun.each(p, fun.take_n(5, fun.enumerate(fun.duplicate('x'))))
		check {{1, 'x'}, {2, 'x'}, {3, 'x'}, {4, 'x'}, {5, 'x'}}
	end)

	it('take_while', function()
		reset()
		fun.each(p, fun.take_while(function(x)
			return x < 5
		end, fun.range(10)))
		check {{1}, {2}, {3}, {4}}

		reset()
		fun.each(p, fun.take_while(function(x)
			return x < 5
		end, fun.range(0)))
		check {}

		reset()
		fun.each(p, fun.take_while(function(x)
			return x > 100 
		end, fun.range(10)))
		check {}

		reset()
		fun.each(p, fun.take_while(function(i, a)
			return i ~= a
		end, fun.enumerate {5, 2, 1, 3, 4}))
		check {{1, 5}}
	end)

	it('take', function()
		reset()
		fun.each(p, fun.take(function(x)
			return x < 5
		end, fun.range(10)))
		check {{1}, {2}, {3}, {4}}

		reset()
		fun.each(p, fun.take(5, fun.duplicate(48)))
		check {{48}, {48}, {48}, {48}, {48}}
	end)

	it('drop_n', function()
		reset()
		fun.each(p, fun.drop_n(5, fun.range(10)))
		check {{6}, {7}, {8}, {9}, {10}}

		reset()
		fun.each(p, fun.drop_n(0, fun.range(5)))
		check {{1}, {2}, {3}, {4}, {5}}

		reset()
		fun.each(p, fun.drop_n(5, fun.range(0)))
		check {}

		reset()
		fun.each(p, fun.drop_n(2, fun.enumerate {'a', 'b', 'c', 'd', 'e'}))
		check {{3, 'c'}, {4, 'd'}, {5, 'e'}}
	end)

	it('drop_while', function()
		reset()
		fun.each(p, fun.drop_while(function(x)
			return x < 5
		end, fun.range(10)))
		check {{5}, {6}, {7}, {8}, {9}, {10}}

		reset()
		fun.each(p, fun.drop_while(function(x)
			return x < 5
		end, fun.range(0)))
		check {}

		reset()
		fun.each(p, fun.drop_while(function(x)
			return x > 100
		end, fun.range(10)))
		check {{1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}}

		reset()
		fun.each(p, fun.drop_while(function(i, a)
			return i ~= a
		end, fun.enumerate {5, 2, 1, 3, 4}))
		check {{2, 2}, {3, 1}, {4, 3}, {5, 4}}

		reset()
		fun.each(p, fun.drop_while(function(i, a)
			return i ~= a
		end, fun.zip({1, 2, 3, 4, 5}, {5, 4, 3, 2, 1})))
		check {{3, 3}, {4, 2}, {5, 1}}
	end)

	it('drop', function()
		reset()
		fun.each(p, fun.drop(5, fun.range(10)))
		check {{6}, {7}, {8}, {9}, {10}}

		reset()
		fun.each(p, fun.drop(function(x)
			return x < 5
		end, fun.range(10)))
		check {{5}, {6}, {7}, {8}, {9}, {10}}
	end)

	it('span', function()
		reset()
		fun.each(p, fun.zip(fun.span(function(x)
			return x < 5
		end, fun.range(10))))
		check {{1, 5}, {2, 6}, {3, 7}, {4, 8}}

		reset()
		fun.each(p, fun.zip(fun.span(5, fun.range(10))))
		check {{1, 6}, {2, 7}, {3, 8}, {4, 9}, {5, 10}}

		reset()
		fun.each(p, fun.zip(fun.span(function(x)
			return x < 5
		end, fun.range(0))))
		check {}

		reset()
		fun.each(p, fun.zip(fun.span(function(x)
			return x < 5
		end, fun.range(5))))
		check {{1, 5}}

		assert.is.equal(fun.split, fun.span)
		assert.is.equal(fun.split_at, fun.span)
	end)
end)

