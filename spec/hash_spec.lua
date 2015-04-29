describe("hashmaps", function()
	local Hash  = require 'hash'

	it("implements (from)", function()
		Hash.from{a = 1, b = 2, c = 3}
	end)
end)
