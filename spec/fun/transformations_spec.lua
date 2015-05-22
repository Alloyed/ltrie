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

	it('map', function()
		local f = function(...)
			return 'map', ...
		end

		reset()
		fun.each(p, fun.map(f, fun.range(0)))
		check {}

		reset()
		fun.each(p, fun.map(f, fun.range(4)))
		check {{'map', 1}, {'map', 2}, {'map', 3}, {'map', 4}}

		reset()
		fun.each(p, fun.map(f, fun.enumerate {'a', 'b', 'c', 'd', 'e'}))
		check {{'map', 1, 'a'}, {'map', 2, 'b'}, {'map', 3, 'c'}, {'map', 4, 'd'}, {'map', 5, 'e'}}

		reset()
		fun.each(p, fun.map(function(x)
			return 2 * x
		end, fun.range(4)))
		check {{2}, {4}, {6}, {8}}
	end)

	it('enumerate', function()
		reset()
		fun.each(p, fun.enumerate {'a', 'b', 'c', 'd', 'e'})
		check {{1, 'a'}, {2, 'b'}, {3, 'c'}, {4, 'd'}, {5, 'e'}}

		reset()
		fun.each(p, fun.enumerate(fun.enumerate(fun.enumerate {'a', 'b', 'c', 'd', 'e'})))
		check {
			{1, 1, 1, 'a'},
			{2, 2, 2, 'b'},
			{3, 3, 3, 'c'},
			{4, 4, 4, 'd'},
			{5, 5, 5, 'e'}
		}

		reset()
		fun.each(p, fun.enumerate(fun.zip(
			{'one', 'two', 'three', 'four', 'five'},
			{'a', 'b', 'c', 'd', 'e'})))
		check {
			{1, 'one', 'a'},
			{2, 'two', 'b'},
			{3, 'three', 'c'},
			{4, 'four', 'd'},
			{5, 'five', 'e'}
		}
	end)

	it('intersperse', function()
		reset()
		fun.each(p, fun.intersperse('x', {}))
		check {}

		reset()
		fun.each(p, fun.intersperse('x', {'a', 'b', 'c', 'd', 'e'}))
		check {{'a'}, {'x'}, {'b'}, {'x'}, {'c'}, {'x'}, {'d'}, {'x'}, {'e'}, {'x'}}

		reset()
		fun.each(p, fun.intersperse('x', {'a', 'b', 'c', 'd', 'e', 'f'}))
		check {{'a'}, {'x'}, {'b'}, {'x'}, {'c'}, {'x'}, {'d'}, {'x'}, {'e'}, {'x'}, {'f'}, {'x'}}
	end)
end)
