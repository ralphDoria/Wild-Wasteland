--!nocheck
--[[
	Shape guard for the consumable config (ItemSystem_ScriptStorage/Data/ConsumableStats). Catches
	a malformed/typo'd entry that would make the ConsumableReceiver reject a real consumable, apply
	a garbage restore value, or silently restore nothing because a stat key is misspelled
	(BUGS.md C3 path; Tier 3 Batch V3 restore shape).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConsumableStats = require(
	ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Data.ConsumableStats
)

local function isPositiveFinite(n: any): boolean
	return type(n) == "number" and n == n and n > 0 and n < math.huge
end

-- The only stat names the server-side restore path knows how to apply. A key outside this
-- set would be silently ignored at runtime — catch the typo here instead.
local restorableStats = {
	Health = true,
	Hunger = true,
	Thirst = true,
	Stamina = true,
}

return function()
	it("defines at least one consumable", function()
		expect(next(ConsumableStats)).to.be.ok()
	end)

	it("every entry restores at least one known stat, by a positive finite amount", function()
		for name, stats in ConsumableStats do
			expect(type(stats.restores) == "table").to.equal(true)
			expect(next(stats.restores)).to.be.ok()
			for statName, amount in stats.restores do
				expect(restorableStats[statName]).to.equal(true)
				expect(isPositiveFinite(amount)).to.equal(true)
			end
		end
	end)

	it("every entry has a finite non-negative cooldown", function()
		for name, stats in ConsumableStats do
			-- cooldown may be 0 (no limit) but must be a finite non-negative number
			expect(type(stats.useCooldown) == "number" and stats.useCooldown >= 0 and stats.useCooldown < math.huge).to.equal(true)
		end
	end)

	it("covers the Healing Injection, restoring Health", function()
		expect(ConsumableStats["Healing Injection"]).to.be.ok()
		expect(isPositiveFinite(ConsumableStats["Healing Injection"].restores.Health)).to.equal(true)
	end)
end
