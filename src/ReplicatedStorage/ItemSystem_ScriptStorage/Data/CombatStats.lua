--!strict
--[[
	Server-authoritative melee combat stats, keyed by tool name. Source of truth in code (not
	per-instance Studio attributes) so weapon balance is version-controlled, reviewable, and
	unit-testable — and the server never trusts a client-sent damage value (BUGS.md C6).

	The MeleeReceiver looks these up by the sender's *equipped* tool name; the client Melee class
	reads the same table so its local prediction/feedback matches the authoritative value.
]]

export type MeleeStats = {
	damage: number,        -- applied via Humanoid:TakeDamage on a validated hit
	swingCooldown: number, -- min seconds between hits on the SAME target. This is an anti-spam floor,
	                       -- NOT the animation length — keep it below a real swing cycle so a
	                       -- legitimate re-swing is never rejected, while remote-spam DPS is capped.
	maxRange: number,      -- max attacker-to-target distance (studs) the server will accept
}

local CombatStats: { [string]: MeleeStats } = {
	["Raider Axe"] = { damage = 50, swingCooldown = 0.35, maxRange = 10 },
	["Barbed Bat"] = { damage = 50, swingCooldown = 0.35, maxRange = 10 },
}

return CombatStats
