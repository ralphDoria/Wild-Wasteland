--!nocheck
--[[
	Specs for the shared server-authority type validators
	(ServerScriptService.../Receivers/Validation). Pure functions, so fully unit-testable.

	These guard the Tier 2 template and the documented gaps:
	- validateNumber lets math.huge through (BUGS.md C6 root) -> isBoundedNumber must reject it.
	- isInteger must reject fractional / infinite quantities (BUGS.md C7).
]]

local ServerScriptService = game:GetService("ServerScriptService")
local Validation = require(
	ServerScriptService.RojoManaged_SSS.ItemSystem_Server.Revamp.Receivers.Validation
)

local NAN = 0 / 0

return function()
	describe("isNumber", function()
		it("accepts finite numbers", function()
			expect(Validation.isNumber(5)).to.equal(true)
			expect(Validation.isNumber(0)).to.equal(true)
			expect(Validation.isNumber(-3.2)).to.equal(true)
		end)

		it("rejects non-numbers and NaN", function()
			expect(Validation.isNumber("5")).to.equal(false)
			expect(Validation.isNumber(nil)).to.equal(false)
			expect(Validation.isNumber(NAN)).to.equal(false)
		end)

		it("ACCEPTS infinity (documented gap — use isBoundedNumber for magnitudes)", function()
			expect(Validation.isNumber(math.huge)).to.equal(true)
		end)
	end)

	describe("isBoundedNumber", function()
		it("accepts finite numbers", function()
			expect(Validation.isBoundedNumber(5)).to.equal(true)
			expect(Validation.isBoundedNumber(-100)).to.equal(true)
		end)

		it("rejects infinity, -infinity and NaN", function()
			expect(Validation.isBoundedNumber(math.huge)).to.equal(false)
			expect(Validation.isBoundedNumber(-math.huge)).to.equal(false)
			expect(Validation.isBoundedNumber(NAN)).to.equal(false)
		end)

		it("enforces inclusive min/max", function()
			expect(Validation.isBoundedNumber(5, 0, 10)).to.equal(true)
			expect(Validation.isBoundedNumber(0, 0, 10)).to.equal(true)
			expect(Validation.isBoundedNumber(10, 0, 10)).to.equal(true)
			expect(Validation.isBoundedNumber(-1, 0, 10)).to.equal(false)
			expect(Validation.isBoundedNumber(11, 0, 10)).to.equal(false)
		end)
	end)

	describe("isInteger", function()
		it("accepts whole numbers", function()
			expect(Validation.isInteger(5)).to.equal(true)
			expect(Validation.isInteger(0)).to.equal(true)
			expect(Validation.isInteger(-2)).to.equal(true)
		end)

		it("rejects fractional, infinite and NaN values", function()
			expect(Validation.isInteger(2.5)).to.equal(false)
			expect(Validation.isInteger(math.huge)).to.equal(false)
			expect(Validation.isInteger(NAN)).to.equal(false)
		end)

		it("supports a positive-integer guard via min = 1 (BUGS.md C7 negative-transfer)", function()
			expect(Validation.isInteger(1, 1)).to.equal(true)
			expect(Validation.isInteger(0, 1)).to.equal(false)
			expect(Validation.isInteger(-5, 1)).to.equal(false)
		end)
	end)

	describe("isInstance", function()
		it("accepts a real instance of the expected class", function()
			local part = Instance.new("Part")
			expect(Validation.isInstance(part, "BasePart")).to.equal(true)
			expect(Validation.isInstance(part, "Part")).to.equal(true)
			part:Destroy()
		end)

		it("rejects the wrong class", function()
			local part = Instance.new("Part")
			expect(Validation.isInstance(part, "Humanoid")).to.equal(false)
			part:Destroy()
		end)

		it("rejects fake-table imposters and nil", function()
			local fakePart = { Position = Vector3.new(), ClassName = "Part" }
			expect(Validation.isInstance(fakePart, "BasePart")).to.equal(false)
			expect(Validation.isInstance(nil, "BasePart")).to.equal(false)
		end)
	end)

	describe("isVector3", function()
		it("accepts a Vector3", function()
			expect(Validation.isVector3(Vector3.new(1, 2, 3))).to.equal(true)
		end)

		it("rejects fakes and NaN components", function()
			expect(Validation.isVector3({ X = 1, Y = 2, Z = 3 })).to.equal(false)
			expect(Validation.isVector3(Vector3.new(NAN, 0, 0))).to.equal(false)
		end)
	end)

	describe("isCFrame", function()
		it("accepts a CFrame", function()
			expect(Validation.isCFrame(CFrame.new(0, 5, 0))).to.equal(true)
		end)

		it("rejects non-CFrames", function()
			expect(Validation.isCFrame(Vector3.new())).to.equal(false)
			expect(Validation.isCFrame({})).to.equal(false)
		end)
	end)

	describe("isSimpleTable", function()
		it("validates key type and every value", function()
			local good = { a = 1, b = 2 }
			expect(Validation.isSimpleTable(good, "string", Validation.isNumber)).to.equal(true)
		end)

		it("rejects non-tables, bad key types and bad values", function()
			expect(Validation.isSimpleTable("nope", "string", Validation.isNumber)).to.equal(false)
			expect(Validation.isSimpleTable({ [1] = 1 }, "string", Validation.isNumber)).to.equal(false)
			expect(Validation.isSimpleTable({ a = "x" }, "string", Validation.isNumber)).to.equal(false)
		end)
	end)
end
