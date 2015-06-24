require 'spec/strict' ()
global('bit32')
global('file')

describe("Persistent Vectors", function()
	local Vector = require 'ltrie.vector'
	local tbl = {}
	for i=1, 2048 do
		table.insert(tbl, 2048 - i)
	end

	local vec
	it("implements from()", function()
		vec = Vector.from(ipairs(tbl))
	end)

	it("implements get()", function()
		for i, v in ipairs(tbl) do
			assert.are.equal(tbl[i], vec:get(i))
		end
	end)

	it("implements len()", function()
		assert.are.equal(#tbl, vec:len())
	end)

	it("implements conj()", function()
		local top = vec:len()
		for _, v in ipairs {'a', 'b', 'c', 'd'} do
			table.insert(tbl, v)
			vec = vec:conj(v)
		end

		for i = top, vec:len() do
			assert.are.equal(tbl[i], vec:get(i))
		end
	end)

	it("implements assoc()", function()
		local l = vec:len()
		local mergeIn = {{l, "TOP"}}
		for i=1, 100 do
			table.insert(mergeIn, {math.random(l), "new#" .. i})
		end
		for _, v in ipairs(mergeIn) do
			local car, cdr = unpack(v)
			tbl[car] = cdr
			vec = vec:assoc(car, cdr)
		end

		for i, v in ipairs(tbl) do
			assert.are.equal(tbl[i], vec:get(i))
		end
	end)

	it("implements pop()", function()
		local l = vec:len()
		assert.not_nil(vec:get(l))
		local v2 = vec:pop()
		assert.is_nil(v2:get(l))
		assert.equal(l - 1, v2:len())
	end)

	it("implements withMutations()", function()
		local v2 = vec:withMutations(function(v)
			return v:conj('c')
		end)

		assert.not_equal(v2:get(v2:len()), vec:get(vec:len()))
	end)
end)

describe("subvec", function()
	local Vector = require 'ltrie.vector'
	local Subvec = require 'ltrie.subvec'
	local fun    = require 'ltrie.fun'

	local vec = Vector.of()
	for i=1, 50 do
		vec = vec:conj(i)
	end

	it("implements get()", function()
		local sv = Subvec.new(vec, 1, 20)
		assert.is.equal(sv:len(), 20)
		for i=1, 20 do
			assert.is.equal(sv:get(i), vec:get(i))
		end

		sv = Subvec.new(vec, 21, 40)
		for i=1, 20 do
			assert.is.equal(sv:get(i), vec:get(i + 20))
		end
	end)

	it("implements ipairs()", function()
		local sv = Subvec.new(vec, 11, 20)
		assert.is.equal(sv:len(), 10)
		for i, v in sv:ipairs() do
			assert.is.equal(v, vec:get(i+10))
		end
	end)

	it("is iterable", function()
		local sv = Subvec.new(vec, 11, 20)
		assert.is.equal(sv:len(), 10)
		fun.each(function(i, v)
			assert.is.equal(v, vec:get(i+10))
		end, fun.enumerate(sv))
	end)

	it("implements conj() and assoc()", function()
		local sv = Subvec.new(vec, 1, 5)

		sv = sv:conj('a')
		assert.is.equal(sv:get(6), 'a')
		assert.is_not.equal(vec:get(6), 'a')

		sv = sv:assoc(2, 'b')
		assert.is.equal(sv:get(2), 'b')
		assert.is_not.equal(vec:get(2), 'b')
	end)

	it("implements pop()", function()
		local sv = Subvec.new(vec, 1, 5)
		assert.is.equal(sv:len(), 5)

		sv = sv:pop()
		assert.is.equal(sv:len(), 4)
	end)
end)
