--!strict
--[[
	Server-authoritative consumable stats, keyed by tool name. Same rationale as CombatStats
	(BUGS.md C6): balance lives in version-controlled, unit-testable code, and the server never
	trusts a client-sent heal amount (BUGS.md C3).

	The ConsumableReceiver looks these up by the sender's *equipped* tool name and applies the
	restores to the sender only: Health goes straight to the humanoid (clamped to MaxHealth),
	Hunger/Thirst/Stamina go through VitalsService.restore (clamped to their config max) —
	the food/drink path that never existed pre-rewrite (BUGS.md M12, Tier 3 Batch V3).
]]

export type ConsumableStats = {
	-- what a validated use restores; keys are "Health", "Hunger", "Thirst", "Stamina"
	restores: { [string]: number },
	useCooldown: number, -- min seconds between uses per player. Anti-spam floor, NOT the
	                     -- animation length — keep it below a real use cycle (equip next item,
	                     -- play the activate animation) so a legitimate re-use is never rejected.
}

local ConsumableStats: { [string]: ConsumableStats } = {
	["Healing Injection"] = {
		restores = { Health = 25 },
		useCooldown = 2,
	},
	-- Add food/drink items here as they're designed — e.g.
	-- ["Bloxy Cola"] = { restores = { Thirst = 30 }, useCooldown = 2 },
}

return ConsumableStats
