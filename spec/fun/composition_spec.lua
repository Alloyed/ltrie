describe("Compositions", function()
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

	it("zip", function()
		reset()
		fun.each(p, fun.zip({'a', 'b', 'c', 'd'}, {'one', 'two', 'three'}))
		check {{'a', 'one'}, {'b', 'two'}, {'c', 'three'}}

		reset()
		fun.each(p, fun.zip())
		check {}

		assert.has_errors(function() fun.each(p, fun.zip(fun.range(0))) end)
		assert.has_errors(function() fun.each(p, fun.zip(fun.range(0), fun.range(0))) end)

		reset()
		p(fun.nth(10, fun.zip(fun.range(1, 100, 3), fun.range(1, 100, 5), fun.range(1, 100, 7))))
		check {{28, 46, 64}}

		reset()
		fun.each(p, fun.zip(fun.partition(function(x) return x > 7 end, fun.range(1, 15, 1))))
		check { {8, 1}, {9, 2}, {10, 3}, {11, 4}, {12, 5}, {13, 6}, {14, 7} }
	end)

	it("cycle", function()
		reset()
		fun.each(p, fun.take(15, fun.cycle{'a', 'b', 'c', 'd', 'e'}))
		check { 
			{'a'}, {'b'}, {'c'}, {'d'}, {'e'},
			{'a'}, {'b'}, {'c'}, {'d'}, {'e'},
			{'a'}, {'b'}, {'c'}, {'d'}, {'e'}
		}

		reset()
		fun.each(p, fun.take(15, fun.cycle(fun.range(5))))
		check {
			{1}, {2}, {3}, {4}, {5},
			{1}, {2}, {3}, {4}, {5},
			{1}, {2}, {3}, {4}, {5}
		}

		reset()
		fun.each(p, fun.take(15, fun.cycle(fun.zip(fun.range(5), {'a', 'b', 'c', 'd', 'e'}))))
		check {
			{1, 'a'}, {2, 'b'}, {3, 'c'}, {4, 'd'}, {5, 'e'},
			{1, 'a'}, {2, 'b'}, {3, 'c'}, {4, 'd'}, {5, 'e'},
			{1, 'a'}, {2, 'b'}, {3, 'c'}, {4, 'd'}, {5, 'e'}
		}
	end)

	it("chain", function()
		reset()
		fun.each(p, fun.chain(fun.range(2)))
		check {{1}, {2}}

		reset()
		fun.each(p, fun.chain(fun.range(2), {'a', 'b', 'c'}, {'one', 'two', 'three'}))
		check {{1}, {2}, {'a'}, {'b'}, {'c'}, {'one'}, {'two'}, {'three'}}

		reset()
		fun.each(p, fun.take(15, fun.cycle(fun.chain(fun.enumerate{'a', 'b', 'c'}, {'one', 'two', 'three'}))))
		check {
			{1, 'a'}, {2, 'b'}, {3, 'c'}, {'one'}, {'two'}, {'three'},
			{1, 'a'}, {2, 'b'}, {3, 'c'}, {'one'}, {'two'}, {'three'},
			{1, 'a'}, {2, 'b'}, {3, 'c'}
		}

		assert.has_errors(function()
			fun.each(p, fun.chain(fun.range(0), fun.range(0), fun.range(0)))
		end)

		assert.has_errors(function()
			fun.each(p, fun.chain(fun.range(0), fun.range(1), fun.range(0)))
		end)
	end)
end)
