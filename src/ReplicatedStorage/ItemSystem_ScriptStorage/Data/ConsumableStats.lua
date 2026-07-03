--!strict
--[[
	Server-authoritative consumable stats, keyed by tool name. Same rationale as CombatStats
	(BUGS.md C6): balance lives in version-controlled, unit-testable code, and the server never
	trusts a client-sent heal amount (BUGS.md C3).

	The ConsumableReceiver looks these up by the sender's *equipped* tool name and applies the
	config amount to the sender's own humanoid only.
]]

export type ConsumableStats = {
	healAmount: number,  -- HP restored on a validated use, clamped to MaxHealth
	useCooldown: number, -- min seconds between uses per player. Anti-spam floor, NOT the
	                     -- animation length — keep it below a real use cycle (equip next item,
	                     -- play the activate animation) so a legitimate re-use is never rejected.
}

local ConsumableStats: { [string]: ConsumableStats } = {
	["Healing Injection"] = { healAmount = 25, useCooldown = 2 },
}

return ConsumableStats
