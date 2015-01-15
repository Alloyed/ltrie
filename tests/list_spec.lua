local List = require 'list'

describe('List', function()
	it('of provides initial values', function()
		local v = List.of('a', 'b', 'c')
		assert.are.equal('a', v:get(1))
		assert.are.equal('b', v:get(2))
		assert.are.equal('c', v:get(3))
	end)

	it('coerces numeric string keys to indexes', function()
		local v = List.of(1, 2, 3, -1);
		assert.are.equal(1, v:get('1'))
		assert.are.equal(2, v:get('2'))
		assert.are.equal(3, v:get('3'))
		assert.are.equal(4, v:set('4', 4):get('3'))
	end)
end)
