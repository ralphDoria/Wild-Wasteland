--!nocheck
--[[
	Shape guard for the vitals config (VitalsSystem_ScriptStorage/Data/VitalsConfig).
	A malformed entry here would make the server sim decay at garbage rates or the
	threshold sectioning misbehave — catch it at spec time like CombatStats/ConsumableStats.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VitalsConfig = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.Data.VitalsConfig)

local function isPositiveFinite(n: any): boolean
	return type(n) == "number" and n == n and n > 0 and n < math.huge
end

return function()
	describe("decay stats (Hunger, Thirst)", function()
		for _, statName in { "Hunger", "Thirst" } do
			local stat = VitalsConfig[statName]

			it(statName .. " has positive finite max, decay rate, and starvation damage", function()
				expect(isPositiveFinite(stat.max)).to.equal(true)
				expect(isPositiveFinite(stat.decayPerSecond)).to.equal(true)
				expect(isPositiveFinite(stat.starvationDamagePerSecond)).to.equal(true)
			end)

			it(statName .. " thresholds ascend strictly from 0 to 1", function()
				local thresholds = stat.thresholds
				expect(#thresholds >= 2).to.equal(true)
				expect(thresholds[1]).to.equal(0)
				expect(thresholds[#thresholds]).to.equal(1)
				for i = 1, #thresholds - 1 do
					expect(thresholds[i] < thresholds[i + 1]).to.equal(true)
				end
			end)
		end
	end)

	describe("Stamina", function()
		it("has positive finite pool and rates", function()
			local stamina = VitalsConfig.Stamina
			expect(isPositiveFinite(stamina.max)).to.equal(true)
			expect(isPositiveFinite(stamina.drainPerSecond)).to.equal(true)
			expect(isPositiveFinite(stamina.regenPerSecond)).to.equal(true)
			expect(type(stamina.regenCooldown) == "number" and stamina.regenCooldown >= 0).to.equal(true)
		end)

		it("costs are affordable from a full pool", function()
			local stamina = VitalsConfig.Stamina
			expect(isPositiveFinite(stamina.jumpCost) and stamina.jumpCost <= stamina.max).to.equal(true)
			expect(isPositiveFinite(stamina.swingCost) and stamina.swingCost <= stamina.max).to.equal(true)
		end)
	end)

	describe("scheduling", function()
		it("tick interval and respawn cooldown are positive and sane", function()
			expect(isPositiveFinite(VitalsConfig.tickInterval)).to.equal(true)
			expect(VitalsConfig.tickInterval <= 5).to.equal(true)
			expect(isPositiveFinite(VitalsConfig.respawnRequestCooldown)).to.equal(true)
		end)
	end)
end
