--!nocheck
--[[
	Shape guard for the consumable config (ItemSystem_ScriptStorage/Data/ConsumableStats). Catches
	a malformed/typo'd entry that would make the ConsumableReceiver reject a real consumable or
	apply a garbage heal value at runtime (BUGS.md C3 path).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConsumableStats = require(
	ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Data.ConsumableStats
)

local function isPositiveFinite(n: any): boolean
	return type(n) == "number" and n == n and n > 0 and n < math.huge
end

return function()
	it("defines at least one consumable", function()
		expect(next(ConsumableStats)).to.be.ok()
	end)

	it("every entry has a positive, finite heal amount and cooldown", function()
		for name, stats in ConsumableStats do
			expect(isPositiveFinite(stats.healAmount)).to.equal(true)
			-- cooldown may be 0 (no limit) but must be a finite non-negative number
			expect(type(stats.useCooldown) == "number" and stats.useCooldown >= 0 and stats.useCooldown < math.huge).to.equal(true)
		end
	end)

	it("covers the Healing Injection", function()
		expect(ConsumableStats["Healing Injection"]).to.be.ok()
	end)
end
