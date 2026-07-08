--!strict
--[[
	All vitals numbers in one version-controlled, shape-tested place (same rationale as
	CombatStats/ConsumableStats). Read by the server sim (VitalsSystem_Server/VitalsService),
	the client views, and the client stamina prediction — so both sides always agree.

	The values preserve pre-rewrite behavior exactly:
	- Hunger decayed 1 point every 4 s   -> 0.25/s
	- Thirst decayed 1 point every 3 s   -> 1/3 /s
	- Each starving stat damaged 1 HP/s
	- Stamina drained 5/s sprinting, regenerated 10/s after a 0.5 s cooldown,
	  jump and melee swing each cost 10.
]]

export type DecayStatConfig = {
	max: number,
	decayPerSecond: number,
	-- HP/s applied while this stat sits at zero (stacks across starving stats)
	starvationDamagePerSecond: number,
	-- ascending proportions [0..1] splitting the bar into sections; section changes drive
	-- the client threshold SFX and low-value tinting
	thresholds: { number },
}

export type StaminaConfig = {
	max: number,
	drainPerSecond: number,
	regenPerSecond: number,
	-- seconds after the last drain/cost before regen starts
	regenCooldown: number,
	jumpCost: number,
	swingCost: number,
	-- horizontal speed (studs/s) above which the server counts a sprinter as moving
	-- (sprint only drains while actually moving, matching the old client behavior)
	movingSpeedThreshold: number,
	-- client prediction snaps to the replicated Stamina attribute when they diverge
	-- by more than this (prediction and 1 Hz authority legitimately drift a little)
	reconcileSnapTolerance: number,
}

export type VitalsConfig = {
	Hunger: DecayStatConfig,
	Thirst: DecayStatConfig,
	Stamina: StaminaConfig,
	-- server sim cadence; these stats change slowly, per-frame ticking is waste
	tickInterval: number,
	-- min seconds between honored RespawnPlayerCharacter requests per player (C16)
	respawnRequestCooldown: number,
}

local VitalsConfig: VitalsConfig = {
	Hunger = {
		max = 100,
		decayPerSecond = 1 / 4,
		starvationDamagePerSecond = 1,
		thresholds = { 0, 0.1, 0.25, 0.5, 1 },
	},
	Thirst = {
		max = 100,
		decayPerSecond = 1 / 3,
		starvationDamagePerSecond = 1,
		thresholds = { 0, 0.1, 0.25, 0.5, 1 },
	},
	Stamina = {
		max = 100,
		drainPerSecond = 5,
		regenPerSecond = 10,
		regenCooldown = 0.5,
		jumpCost = 10,
		swingCost = 10,
		movingSpeedThreshold = 0.5,
		reconcileSnapTolerance = 15,
	},
	tickInterval = 1,
	respawnRequestCooldown = 1,
}

return VitalsConfig
