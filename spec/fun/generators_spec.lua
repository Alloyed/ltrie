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

	it("range", function()
		local function test_range1(e)
			reset()
			fun.each(p, fun.range(e))
			local t = T
			reset()
			for i=1, e do p(i) end
			check(t)
		end

		local function test_range2(b, e)
			reset()
			fun.each(p, fun.range(b, e))
			local t = T
			reset()
			for i=b, e do p(i) end
			check(t)
		end

		local function test_range3(b, e, s)
			reset()
			fun.each(p, fun.range(b, e, s))
			local t = T
			reset()
			for i=b, e, s do p(i) end
			check(t)
		end

		test_range1(0)
		test_range2(0, 0)
		test_range1(5)
		test_range2(0, 5)
		test_range3(0, 5, 1)
		test_range3(0, 10, 2)

		reset()
		fun.each(p, fun.range(-5))
		local t = T
		reset()
		for i=-1, -5, -1 do p(i) end
		check(t)

		test_range3(0, -5, 1)
		test_range3(0, -5, -1)
		test_range3(0, -10, -2)
		test_range3(1.2, 1.6, 0.1)
		assert.has_errors(function()
			test_range3(0, 5, 0)
		end)
	end)

	it("duplicate", function()
		reset()
		fun.each(p, fun.take(5, fun.duplicate(48)))
		check {{48}, {48}, {48}, {48}, {48}}

		reset()
		fun.each(p, fun.take(5, fun.duplicate(1, 2, 3, 4, 5)))
		check {
			{1, 2, 3, 4, 5},
			{1, 2, 3, 4, 5},
			{1, 2, 3, 4, 5},
			{1, 2, 3, 4, 5},
			{1, 2, 3, 4, 5}
		}

		assert.is.equal(fun.xrepeat, fun.duplicate)
		assert.is.equal(fun.replicate, fun.duplicate)
	end)

	it("rands", function()
		math.randomseed(0xDEADBEEF)
		assert.is_true(fun.all(function(x)
			return x >= 0 and x < 1
		end, fun.take(5, fun.rands())))

		assert.has_errors(function()
			fun.take(5, fun.rands(0))
		end)

		assert.is_true(fun.all(function(x)
			return math.floor(x) == x
		end, fun.take(5, fun.rands(10))))

		assert.is_true(fun.all(function(x)
			return math.floor(x) == x
		end, fun.take(5, fun.rands(1024))))

		reset()
		fun.each(p, fun.take(5, fun.rands(0, 1)))
		check {{0}, {0}, {0}, {0}, {0}}

		reset()
		fun.each(p, fun.take(5, fun.rands(5, 6)))
		check {{5}, {5}, {5}, {5}, {5}}

		assert.is_true(fun.all(function(x)
			return x >= 10 and x < 20
		end, fun.take(20, fun.rands(10, 20))))
	end)

	it("misc", function()
		-- tabulate
		reset()
		fun.each(p, fun.take(5, fun.tabulate(function(x)
			return 2 * x
		end)))
		check {{0}, {2}, {4}, {6}, {8}}

		-- zeros
		reset()
		fun.each(p, fun.take(5, fun.zeros()))
		check {{0}, {0}, {0}, {0}, {0}}
		
		-- ones
		reset()
		fun.each(p, fun.take(5, fun.ones()))
		check {{1}, {1}, {1}, {1}, {1}}
	end)
end)

