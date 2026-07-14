--!strict
--[[
	Pure level-curve math (no Instances, no services) — TestEZ-covered by XPCurve.spec.

	The durable stat is CUMULATIVE XP; level is always derived from it here, never stored
	independently (see docs/XP_SYSTEM_RESEARCH.md — avoids xp/level drift and makes curve
	retunes retroactive). Requirement family: exponential per-level,
	xpToAdvance(level) = round(baseXP * growthRate^(level - 1)), clamped at maxLevel.
]]

local XPConfig = require(script.Parent.Parent.Data.XPConfig)

type CurveConfig = XPConfig.CurveConfig

local XPCurve = {}

-- XP needed to advance FROM `level` to level+1. Levels at/above the cap never advance.
function XPCurve.xpToAdvance(config: CurveConfig, level: number): number
	if level >= config.maxLevel then
		return math.huge
	end
	return math.floor(config.baseXP * config.growthRate ^ (level - 1) + 0.5)
end

-- Cumulative XP at which `level` is first reached (level 1 = 0 XP).
function XPCurve.totalXPForLevel(config: CurveConfig, level: number): number
	local total = 0
	for l = 1, math.min(level, config.maxLevel) - 1 do
		total += XPCurve.xpToAdvance(config, l)
	end
	return total
end

-- Level for a cumulative XP amount. Total ordering: monotonic, clamped to [1, maxLevel].
function XPCurve.levelForTotalXP(config: CurveConfig, totalXP: number): number
	local level = 1
	local remaining = math.max(0, totalXP)
	while level < config.maxLevel do
		local needed = XPCurve.xpToAdvance(config, level)
		if remaining < needed then
			break
		end
		remaining -= needed
		level += 1
	end
	return level
end

-- Everything a progress bar needs, in one call.
export type Progress = {
	level: number,
	intoLevel: number, -- XP earned within the current level
	required: number, -- XP needed to complete the current level (math.huge at cap)
	fraction: number, -- intoLevel / required, in [0, 1]; 1 at the cap
}

function XPCurve.progress(config: CurveConfig, totalXP: number): Progress
	local level = XPCurve.levelForTotalXP(config, totalXP)
	local intoLevel = math.max(0, totalXP) - XPCurve.totalXPForLevel(config, level)
	local required = XPCurve.xpToAdvance(config, level)
	local fraction = if required == math.huge then 1 else math.clamp(intoLevel / required, 0, 1)
	return {
		level = level,
		intoLevel = intoLevel,
		required = required,
		fraction = fraction,
	}
end

return XPCurve
