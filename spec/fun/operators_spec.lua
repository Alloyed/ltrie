describe("Operators", function()
	local fun = require 'ltrie.fun'
	local op = fun.operator

	it("comparisons", function()
		local o = op.le
		assert.is_true  (o(0, 1))
		assert.is_false (o(1, 0))
		assert.is_true  (o(0, 0))
		assert.is_true  (o('abc', 'cde'))
		assert.is_false (o('cde', 'abc'))
		assert.is_true  (o('abc', 'abc'))

		local o = op.lt
		assert.is_true  (o(0, 1))
		assert.is_false (o(1, 0))
		assert.is_false (o(0, 0))
		assert.is_true  (o('abc', 'cde'))
		assert.is_false (o('cde', 'abc'))
		assert.is_false (o('abc', 'abc'))

		local o = op.eq
		assert.is_false (o(0, 1))
		assert.is_false (o(1, 0))
		assert.is_true  (o(0, 0))
		assert.is_false (o('abc', 'cde'))
		assert.is_false (o('cde', 'abc'))
		assert.is_true  (o('abc', 'abc'))

		local o = op.ne
		assert.is_true  (o(0, 1))
		assert.is_true  (o(1, 0))
		assert.is_false (o(0, 0))
		assert.is_true  (o('abc', 'cde'))
		assert.is_true  (o('cde', 'abc'))
		assert.is_false (o('abc', 'abc'))

		local o = op.ge
		assert.is_false (o(0, 1))
		assert.is_true  (o(1, 0))
		assert.is_true  (o(0, 0))
		assert.is_false (o('abc', 'cde'))
		assert.is_true  (o('cde', 'abc'))
		assert.is_true  (o('abc', 'abc'))

		local o = op.gt
		assert.is_false (o(0, 1))
		assert.is_true  (o(1, 0))
		assert.is_false (o(0, 0))
		assert.is_false (o('abc', 'cde'))
		assert.is_true  (o('cde', 'abc'))
		assert.is_false (o('abc', 'abc'))
	end)

	it("arithmetic", function()
		assert.is.equal(0,  op.add(-1.0, 1.0))
		assert.is.equal(0,  op.add(0, 0))
		assert.is.equal(14, op.add(12, 2))

		local function is_close(state, args)
			local a, b = unpack(args)
			return math.abs(a - b) <= 1e-8
		end
		local say = require 'say'
		say:set("assert.is_close.positive", "Expected %s to be close to %s")
		say:set("assert.is_close.negative", "Expected %s to be far from %s")
		assert:register('assertion', 'close', is_close,
		                "assert.is_close.positive", "assert.is_close.negative")

		assert.is.equal(5, op.div(10, 2))
		assert.is.close(3.3333333333333,  op.div(10, 3))
		assert.is.close(-3.3333333333333, op.div(-10, 3))

		assert.is.equal(3, op.floordiv(10, 3))
		assert.is.equal(3, op.floordiv(11, 3))
		assert.is.equal(4, op.floordiv(12, 3))
		assert.is.equal(-4, op.floordiv(-10, 3))
		assert.is.equal(-4, op.floordiv(-11, 3))
		assert.is.equal(-4, op.floordiv(-12, 3))

		assert.is.equal(3, op.intdiv(10, 3))
		assert.is.equal(3, op.intdiv(11, 3))
		assert.is.equal(4, op.intdiv(12, 3))
		assert.is.equal(-3, op.intdiv(-10, 3))
		assert.is.equal(-3, op.intdiv(-11, 3))
		assert.is.equal(-4, op.intdiv(-12, 3))

		assert.is.close(3.3333333333333, op.truediv(10, 3))
		assert.is.close(3.6666666666667, op.truediv(11, 3))
		assert.is.equal(4, op.truediv(12, 3))
		assert.is.close(-3.3333333333333, op.truediv(-10, 3))
		assert.is.close(-3.6666666666667, op.truediv(-11, 3))
		assert.is.equal(-4, op.truediv(-12, 3))

		assert.is.equal(0, op.mod(10,  2))
		assert.is.equal(1, op.mod(10,  3))
		assert.is.equal(2, op.mod(-10, 3))

		assert.is.equal(1, op.mul(10, 0.1))
		assert.is.equal(0, op.mul(0,    0))
		assert.is.equal(1, op.mul(-1,  -1))

		assert.is.equal(-1, op.neq(1))
		assert.is.equal(true, op.neq(0) == 0)
		assert.is.equal(true, op.neq(-0) == 0)
		assert.is.equal(1, op.neq(-1))

		assert.is.equal(-1, op.unm(1))
		assert.is.equal(true, op.unm(0) == 0)
		assert.is.equal(true, op.unm(-0) == 0)
		assert.is.equal(1, op.unm(-1))

		assert.is.equal(8, op.pow(2,  3))
		assert.is.equal(0, op.pow(0, 10))
		assert.is.equal(1, op.pow(2,  0))

		assert.is.equal(-1, op.sub(2,  3))
		assert.is.equal(-10, op.sub(0, 10))
		assert.is.equal(0, op.sub(2,  2))
	end)

	it("logical", function()
		local o = op.land
		assert.is.equal(true,  o(true, true))
		assert.is.equal(false, o(true, false))
		assert.is.equal(false, o(false, true))
		assert.is.equal(false, o(false, false))
		assert.is.equal(0,     o(1, 0))
		assert.is.equal(1,     o(0, 1))
		assert.is.equal(1,     o(1, 1))
		assert.is.equal(0,     o(0, 0))

		local o = op.lor
		assert.is.equal(true,  o(true, true))
		assert.is.equal(true,  o(true, false))
		assert.is.equal(true,  o(false, true))
		assert.is.equal(false, o(false, false))
		assert.is.equal(1,     o(1, 0))
		assert.is.equal(0,     o(0, 1))
		assert.is.equal(1,     o(1, 1))
		assert.is.equal(0,     o(0, 0))

		assert.is.equal(false, op.lnot(true))
		assert.is.equal(true,  op.lnot(false))
		assert.is.equal(1,     op.lor(1))
		assert.is.equal(0,     op.lor(0))

		assert.is.equal(true,  op.truth(true))
		assert.is.equal(false, op.truth(false))
		assert.is.equal(true,  op.truth(1))
		assert.is.equal(true,  op.truth(0))
		assert.is.equal(false, op.truth(nil))
		assert.is.equal(true,  op.truth(""))
		assert.is.equal(true,  op.truth({}))
	end)
end)

