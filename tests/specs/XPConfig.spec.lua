--!nocheck
--[[
	Shape guard for XPSystem_ScriptStorage/Data/XPConfig: sane curve knobs and award
	values, so a bad tuning edit fails a spec instead of silently breaking progression.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XPConfig = require(ReplicatedStorage.RojoManaged_RS.XPSystem_ScriptStorage.Data.XPConfig)

local function isPositiveFinite(n)
	return type(n) == "number" and n == n and n ~= math.huge and n > 0
end

return function()
	describe("curve", function()
		it("has positive finite baseXP and an integer maxLevel > 1", function()
			expect(isPositiveFinite(XPConfig.curve.baseXP)).to.equal(true)
			expect(isPositiveFinite(XPConfig.curve.maxLevel)).to.equal(true)
			expect(XPConfig.curve.maxLevel % 1).to.equal(0)
			expect(XPConfig.curve.maxLevel > 1).to.equal(true)
		end)
		it("has growthRate >= 1 (requirements must never shrink)", function()
			expect(isPositiveFinite(XPConfig.curve.growthRate)).to.equal(true)
			expect(XPConfig.curve.growthRate >= 1).to.equal(true)
		end)
	end)

	describe("awards", function()
		it("has the kill awards the damage receivers grant", function()
			expect(XPConfig.awards.KillNPC).to.be.ok()
			expect(XPConfig.awards.KillPlayer).to.be.ok()
		end)
		it("every award is a positive finite amount keyed by a name", function()
			local count = 0
			for name, amount in XPConfig.awards do
				count += 1
				expect(type(name)).to.equal("string")
				expect(isPositiveFinite(amount)).to.equal(true)
			end
			expect(count > 0).to.equal(true)
		end)
	end)
end
