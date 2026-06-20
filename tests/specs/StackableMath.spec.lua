--!nocheck
--[[
	Specs for the pure stackable arithmetic (ServerScriptService.../Receivers/Components/StackableMath).

	The headline case is BUGS.md C7: a NEGATIVE quantityToTransfer used to pass the old
	`assert(amount < originalSourceQuantity)` and duplicate the stack (source ends with MORE than it
	started, destination goes negative). `canTransfer` must reject it — while still allowing the
	legitimate `transfer 0` cleanup that SplittingMenuManager relies on.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local StackableMath = require(
	ServerScriptService.RojoManaged_SSS.ItemSystem_Server.Revamp.Receivers.Components.StackableMath
)

local NAN = 0 / 0

return function()
	describe("merge", function()
		it("combines stacks below the cap and depletes the source", function()
			-- 20 + 30 = 50, cap 100: destination holds 50, source is emptied.
			local newDest, newSource, destroySource = StackableMath.merge(20, 30, 100)
			expect(newDest).to.equal(50)
			expect(newSource <= 0).to.equal(true)
			expect(destroySource).to.equal(true)
		end)

		it("caps the destination and leaves the overflow in the source", function()
			-- 60 + 70 = 130, cap 100: destination caps at 100, source keeps the 30 overflow.
			local newDest, newSource, destroySource = StackableMath.merge(60, 70, 100)
			expect(newDest).to.equal(100)
			expect(newSource).to.equal(30)
			expect(destroySource).to.equal(false)
		end)

		it("treats an exact fill as a depleted source", function()
			local newDest, _, destroySource = StackableMath.merge(40, 60, 100)
			expect(newDest).to.equal(100)
			expect(destroySource).to.equal(true)
		end)
	end)

	describe("canTransfer", function()
		it("accepts whole amounts strictly within the pool", function()
			-- pool = 10; valid destination amounts are 0..9 (source keeps >= 1).
			expect(StackableMath.canTransfer(10, 0, 5)).to.equal(true)
			expect(StackableMath.canTransfer(7, 3, 9)).to.equal(true)
		end)

		it("allows transfer 0 (the SplittingMenuManager cleanup call)", function()
			expect(StackableMath.canTransfer(10, 0, 0)).to.equal(true)
		end)

		it("REJECTS a negative transfer (C7 duplication exploit)", function()
			expect(StackableMath.canTransfer(10, 0, -5)).to.equal(false)
			expect(StackableMath.canTransfer(5, 5, -1)).to.equal(false)
		end)

		it("rejects amount >= pool (would empty the source)", function()
			expect(StackableMath.canTransfer(10, 0, 10)).to.equal(false)
			expect(StackableMath.canTransfer(6, 4, 11)).to.equal(false)
		end)

		it("rejects fractional, NaN, and non-number amounts", function()
			expect(StackableMath.canTransfer(10, 0, 2.5)).to.equal(false)
			expect(StackableMath.canTransfer(10, 0, NAN)).to.equal(false)
			expect(StackableMath.canTransfer(10, 0, "5" :: any)).to.equal(false)
		end)
	end)

	describe("transfer", function()
		it("splits the pool: destination gets amount, source keeps the rest", function()
			-- pool 10, transfer 4 into destination: source 6, destination 4.
			local newSource, newDest = StackableMath.transfer(10, 0, 4)
			expect(newSource).to.equal(6)
			expect(newDest).to.equal(4)
		end)

		it("conserves the total quantity (no duplication, no loss)", function()
			local newSource, newDest = StackableMath.transfer(7, 3, 4)
			expect(newSource + newDest).to.equal(10)
		end)
	end)
end
