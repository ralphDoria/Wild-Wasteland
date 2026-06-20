--!nocheck
-- Sanity spec: proves the TestEZ harness is wired up correctly.
-- Delete once the first real suite (StackableReceiver math, slot finders, validators) lands.

return function()
	describe("TestEZ harness", function()
		it("runs specs and evaluates matchers", function()
			expect(1 + 1).to.equal(2)
			expect(true).to.be.ok()
		end)
	end)
end
