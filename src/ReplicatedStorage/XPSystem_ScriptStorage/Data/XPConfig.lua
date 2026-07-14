--!strict
--[[
	Level/XP tuning (see docs/XP_SYSTEM_RESEARCH.md).

	Shared (client UI may render the curve), but ONLY the server ever mutates XP —
	XPService is the single award surface and there are no XP remotes.

	To make a NEW action grant XP: add a key to `awards` here, then call
	`XPService.award(player, "<TheKey>")` from the server code that validated the action.
	That is the entire contract.
]]

export type CurveConfig = {
	baseXP: number, -- XP required to go level 1 -> 2
	growthRate: number, -- per-level multiplier on the requirement (>= 1)
	maxLevel: number, -- level is clamped here; total XP keeps accruing past it
}

local XPConfig = {}

XPConfig.curve = {
	baseXP = 100,
	growthRate = 1.12,
	maxLevel = 50,
} :: CurveConfig

-- Award name -> XP granted. Values are placeholders until balance tuning.
XPConfig.awards = {
	KillNPC = 50,
	KillPlayer = 150,
} :: { [string]: number }

return XPConfig
