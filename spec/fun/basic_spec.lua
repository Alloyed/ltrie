describe("Basic", function()
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

	it("Arrays", function()
		reset()
		for _it, a in fun.iter{1, 2, 3} do p(a) end
		check {{1}, {2}, {3}}

		reset()
		for _it, a in fun.iter(fun.iter(fun.iter{1, 2, 3})) do p(a) end
		check {{1}, {2}, {3}}

		reset()
		for _it, a in fun.wrap(fun.wrap(fun.iter{1, 2, 3})) do p(a) end
		check {{1}, {2}, {3}}

		reset()
		for _it, a in fun.wrap(fun.wrap(ipairs{1, 2, 3})) do p(a) end
		check {{1}, {2}, {3}}
		
		reset()
		for _it, a in fun.iter{} do p(a) end
		check {}
		
		reset()
		for _it, a in fun.iter(fun.iter(fun.iter{})) do p(a) end
		check {}

		reset()
		for _it, a in fun.wrap(fun.wrap(fun.iter{})) do p(a) end
		check {}

		reset()
		for _it, a in fun.wrap(fun.wrap(ipairs{})) do p(a) end
		check {}

		-- check that iter() is equivalent to ipairs()
		local t = {1, 2, 3}
		local t1 = {fun.iter(t):unwrap()}
		local t2 = {ipairs(t)}
		assert.are.same(t1, t2)

		-- check that wrap() does nothing to wrapped iterators
		local t1 = {fun.iter{1, 2, 3}}
		local t2 = {fun.wrap(unpack(t1)):unwrap()}
		assert.are.same(t1, t2)
	end)

	it("Maps", function()
		reset()
		t = {}
		for _it, k, v in fun.iter{a = 1, b = 2, c = 3} do
			t[#t + 1] = k
		end
		table.sort(t)
		for _it, v in fun.iter(t) do
			p(v)
		end
		check {{'a'}, {'b'}, {'c'}}

		reset()
		t = {}
		for _it, k, v in fun.iter(fun.iter(fun.iter{a = 1, b = 2, c = 3})) do
			t[#t + 1] = k
		end
		table.sort(t)
		for _it, v in fun.iter(t) do
			p(v)
		end
		check {{'a'}, {'b'}, {'c'}}


		reset()
		t = {}
		for _it, k, v in fun.iter{} do
			p(k, v)
		end
		check {}

		reset()
		t = {}
		for _it, k, v in fun.iter(fun.iter(fun.iter{})) do
			p(k, v)
		end
		check {}
	end)

	it("Strings", function()
		reset()
		for _it, a in fun.iter("abcd") do p(a) end
		check {{'a'}, {'b'}, {'c'}, {'d'}}

		reset()
		for _it, a in fun.iter(fun.iter(fun.iter("abcd"))) do p(a) end
		check {{'a'}, {'b'}, {'c'}, {'d'}}

		reset()
		for _it, a in fun.iter("") do p(a) end
		check {}

		reset()
		for _it, a in fun.iter(fun.iter(fun.iter(""))) do p(a) end
		check {}
	end)

	it("Custom Generators", function() 
		local function mypairs_gen(max, state)
			if state >= max then
				return nil
			end
			return state + 1, state + 1
		end

		local function mypairs(max)
			return mypairs_gen, max, 0
		end

		reset()
		for _it, a in fun.iter(mypairs(10)) do p(a) end
		check {{1}, {2}, {3}, {4}, {5}, {6}, {7}, {8}, {9}, {10}}

		assert.has_errors(function()
			reset()
			for _it, a in fun.iter(1) do p(a) end
		end)

		assert.has_errors(function()
			reset()
			for _it, a in fun.iter(1, 2, 3) do p(a) end
		end)
	end)

	it("each", function()
		reset()
		fun.each(p, {1, 2, 3})
		check {{1}, {2}, {3}}

		reset()
		fun.each(p, fun.iter{1, 2, 3})
		check {{1}, {2}, {3}}

		reset()
		fun.each(p, fun.iter{})
		check {}

		local ks, vs = {}, {}
		fun.each(function(k, v) table.insert(ks, k) table.insert(vs, v) end,
		         {a = 1, b = 2, c = 3})
		reset()
		table.sort(ks)
		fun.each(p, ks)
		check({{'a'}, {'b'}, {'c'}})
		reset()
		table.sort(vs)
		fun.each(p, vs)
		check({{1}, {2}, {3}})

		reset()
		fun.each(p, "abc")
		check({{'a'}, {'b'}, {'c'}})

		reset()
		fun.each(p, fun.iter "abc")
		check({{'a'}, {'b'}, {'c'}})

		assert.is.equal(fun.each, fun.for_each)
		assert.is.equal(fun.each, fun.foreach)
	end)

	it("totable", function()
		local tab = fun.totable(fun.range(5))
		assert.is.equal(type(tab), "table")
		assert.is.equal(#tab, 5)
		reset()
		fun.each(p, tab)
		check {{1}, {2}, {3}, {4}, {5}}

		tab = fun.totable(fun.range(0))
		assert.is.equal(type(tab), "table")
		assert.is.equal(#tab, 0)
		reset()
		fun.each(p, tab)
		check {}

		tab = fun.totable("abcdef")
		assert.is.equal(type(tab), "table")
		assert.is.equal(#tab, 6)
		reset()
		fun.each(p, tab)
		check {{'a'}, {'b'}, {'c'}, {'d'}, {'e'}, {'f'}}

		tab = fun.totable {'a', {'b', 'c'}, {'d', 'e', 'f'}}
		assert.is.equal(type(tab), "table")
		assert.is.equal(#tab, 3)
		reset()
		fun.each(p, tab[1])
		fun.each(p, fun.map(unpack, fun.drop(1, tab)))
		check {{'a'}, {'b', 'c'}, {'d', 'e','f'}}
	end)

	it("tomap", function()
		local tab = fun.tomap{a = 1, b = 2, c = 3}
		assert.is.equal(type(tab), "table")
		assert.is.equal(#tab, 0)
		local t = {}
		for _it, k, v in fun.iter(tab) do t[v] = k end
		table.sort(t)
		reset()
		for k, v in ipairs(t) do p(k, v) end
		check {{1, 'a'}, {2, 'b'}, {3, 'c'}}

		local tab = fun.tomap(fun.enumerate("abcdef"))
		assert.is.equal(type(tab), "table")
		assert.is.equal(#tab, 6)
		reset()
		fun.each(p, tab)
		check {{'a'}, {'b'}, {'c'}, {'d'}, {'e'}, {'f'}}
	end)
end)

