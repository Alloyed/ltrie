require 'spec/strict' ()
global 'bit32'
global 'file'
global 'level'

describe("Persistent Vectors", function()
	local Vector = require 'ltrie.vector'

	local _tbl = {}
	for i=1, 2048 do
		table.insert(_tbl, 2048 - i)
	end

	local _vec = Vector.from(ipairs(_tbl))

	local vec, tbl, tl
	before_each(function()
		tbl = setmetatable({}, {__index = _tbl})
		tl = #_tbl
		vec = _vec
	end)

	it("implements get()", function()
		for i, v in vec:ipairs() do
			assert.equal(tbl[i], vec:get(i))
		end
	end)

	it("implements len()", function()
		assert.equal(tl, vec:len())
	end)

	it("implements conj()", function()
		local top = vec:len()
		for _, v in ipairs {'a', 'b', 'c', 'd'} do
			tl = tl + 1
			tbl[tl] = v
			vec = vec:conj(v)
		end

		for i = top, vec:len() do
			assert.equal(tbl[i], vec:get(i))
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

		for i, v in vec:ipairs() do
			assert.equal(tbl[i], vec:get(i))
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

		assert.equal('c', v2:get(v2:len()))
		assert.not_equal(v2:get(v2:len()), vec:get(vec:len()))
	end)

	it("implements unpack()", function()
		local v = Vector.of(3, 2, 1)
		assert.same({v:unpack()}, {3, 2, 1})
	end)
end)

describe("Transient vectors", function()
	local Vector = require 'ltrie.vector'

	local _tbl = {}
	for i=1, 2048 do
		table.insert(_tbl, 2048 - i)
	end
	local _vec = Vector.from(ipairs(_tbl))

	local vec, tbl, tl
	before_each(function()
		tbl = setmetatable({}, {__index = _tbl})
		tl = #_tbl
		vec = _vec
	end)

	it("can conj()", function()
		local add = { 'a', 'b', 'c', 'd', 'e' }
		local e = vec:len()
		local v2 = vec:withMutations(function(v)
			for i, _v in ipairs(add) do
				v = v:conj(_v)
			end
			return v
		end)
		for i, v in ipairs(add) do
			assert.equal(v, v2:get(e + i))
		end
	end)

	it("can assoc()", function()
		local l = vec:len()
		local mergeIn = {{l, "TOP"}}
		for i=1, 100 do
			table.insert(mergeIn, {math.random(l), "new#" .. i})
		end
		local v2 = vec:withMutations(function(v)
			for _, val in ipairs(mergeIn) do
				local car, cdr = unpack(val)
				tbl[car] = cdr
				v = v:assoc(car, cdr)
			end
			return v
		end)

		for _, pair in ipairs(mergeIn) do
			local i, v = unpack(pair)
			assert.equal(tbl[i], v2:get(i))
			assert.not_equal(v2:get(i), vec:get(i))
		end
	end)

	it("can pop()", function()
		local v2 = vec:withMutations(function(v)
			for i=1, 20 do
				v:pop()
			end
			return v
		end)
		assert.equal(vec:len() - 20, v2:len())
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

	it("implements len()", function()
		local sv = Subvec.new(vec, 1, 2)
		assert.equal(sv:len(), 2)

		local sv = Subvec.new(vec, 2, 2)
		assert.equal(sv:len(), 1)

		local sv = Subvec.new(vec, 2, 50)
		assert.equal(sv:len(), 49)
	end)

	it("implements get()", function()
		local sv = Subvec.new(vec, 1, 20)
		assert.equal(sv:len(), 20)
		for i=1, 20 do
			assert.equal(sv:get(i), vec:get(i))
		end

		sv = Subvec.new(vec, 21, 40)
		for i=1, 20 do
			assert.equal(sv:get(i), vec:get(i + 20))
		end
	end)

	it("implements ipairs()", function()
		local sv = Subvec.new(vec, 11, 20)
		assert.equal(sv:len(), 10)
		for i, v in sv:ipairs() do
			assert.equal(v, vec:get(i+10))
		end
	end)

	it("is iterable", function()
		local sv = Subvec.new(vec, 11, 20)
		assert.equal(sv:len(), 10)
		fun.each(function(i, v)
			assert.equal(v, vec:get(i+10))
		end, fun.enumerate(sv))
	end)

	it("implements conj() and assoc()", function()
		local sv = Subvec.new(vec, 1, 5)

		sv = sv:conj('a')
		assert.equal(sv:get(6), 'a')
		assert.not_equal(vec:get(6), 'a')

		sv = sv:assoc(2, 'b')
		assert.equal(sv:get(2), 'b')
		assert.not_equal(vec:get(2), 'b')
	end)

	it("implements pop()", function()
		local sv = Subvec.new(vec, 1, 5)
		assert.equal(sv:len(), 5)

		sv = sv:pop()
		assert.equal(sv:len(), 4)
	end)
end)
