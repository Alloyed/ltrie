describe("Filtering", function()
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

	it("filter", function()
		reset()
		fun.each(p, fun.filter(function(x)
			return x % 3 == 0 
		end, fun.range(10)))
		check {{3}, {6}, {9}}

		reset()
		fun.each(p, fun.take(5, fun.filter(function(i, x)
			return x % 3 == 0
		end, fun.range(0))))
		check {}

		reset()
		fun.each(p, fun.take(5, fun.filter(function(i, x)
			return i % 3 == 0
		end, fun.enumerate(fun.duplicate('x')))))
		check {{3, 'x'}, {6, 'x'}, {9, 'x'}, {12, 'x'}, {15, 'x'}}

		local function filter_fun(a, b, c)
			return a % 16 == 0
		end

		local function test3(a, b, c)
			return a, c, b
		end

		local n = 50
		reset()
		fun.each(p, fun.filter(filter_fun,
					fun.map(test3,
					fun.zip(fun.range(0, n, 1),
							fun.range(0, n, 2),
							fun.range(0, n, 3)))))
		check {{0, 0, 0}, {16, 48, 32}}

		assert.is_equal(fun.remove_if, fun.filter)
	end)

	it("grep", function()
		local lines_to_grep = {
			[[Lorem ipsum dolor sit amet, consectetur adipisicing elit, ]],
			[[sed do eiusmod tempor incididunt ut labore et dolore magna ]],
			[[aliqua. Ut enim ad minim veniam, quis nostrud exercitation ]],
			[[ullamco laboris nisi ut aliquip ex ea commodo consequat.]],
			[[Duis aute irure dolor in reprehenderit in voluptate velit ]],
			[[esse cillum dolore eu fugiat nulla pariatur. Excepteur sint ]],
			[[occaecat cupidatat non proident, sunt in culpa qui officia ]],
			[[deserunt mollit anim id est laborum.]]
		}
		reset()
		fun.each(p, fun.grep("lab", lines_to_grep))
		check {
			{[[sed do eiusmod tempor incididunt ut labore et dolore magna ]]},
			{[[ullamco laboris nisi ut aliquip ex ea commodo consequat.]]},
			{[[deserunt mollit anim id est laborum.]]}
		}

		lines_to_grep = {
			[[Emily]],
			[[Chloe]],
			[[Megan]],
			[[Jessica]],
			[[Emma]],
			[[Sarah]],
			[[Elizabeth]],
			[[Sophie]],
			[[Olivia]],
			[[Lauren]]
		}
		reset()
		fun.each(p, fun.grep("^Em", lines_to_grep))
		check {{[[Emily]]}, {[[Emma]]}}
	end)

	it("partition", function()
		reset()
		fun.each(p, fun.zip(fun.partition(function(i, x)
			return i % 3 == 0
		end, fun.range(10))))
		check {{3, 1}, {6, 2}, {9, 4}}
	end)
end)

