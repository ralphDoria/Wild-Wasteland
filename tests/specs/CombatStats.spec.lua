--!nocheck
--[[
	Shape guard for the melee combat config (ItemSystem_ScriptStorage/Data/CombatStats). Cheap, but
	catches a malformed/typo'd entry that would otherwise make the MeleeReceiver reject a weapon or
	apply a garbage damage value at runtime (BUGS.md C6 path).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatStats = require(
	ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Data.CombatStats
)

local function isPositiveFinite(n: any): boolean
	return type(n) == "number" and n == n and n > 0 and n < math.huge
end

return function()
	it("defines at least one weapon", function()
		expect(next(CombatStats)).to.be.ok()
	end)

	it("every entry has positive, finite damage / cooldown / range", function()
		for name, stats in CombatStats do
			expect(isPositiveFinite(stats.damage)).to.equal(true)
			-- cooldown may be 0 (no limit) but must be a finite non-negative number
			expect(type(stats.swingCooldown) == "number" and stats.swingCooldown >= 0 and stats.swingCooldown < math.huge).to.equal(true)
			expect(isPositiveFinite(stats.maxRange)).to.equal(true)
		end
	end)
end
