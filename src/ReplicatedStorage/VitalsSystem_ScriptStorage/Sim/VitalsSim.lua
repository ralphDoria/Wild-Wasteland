--!strict
--[[
	Pure vitals math — no Roblox APIs, no state. The server sim (VitalsService) and the
	client stamina prediction run these exact functions so authority and prediction can't
	drift, and TestEZ can pin every branch (tests/specs/VitalsSim.spec.lua).
]]

local VitalsSim = {}

-- Decay a stat toward zero. Never goes negative, never grows.
function VitalsSim.decay(value: number, ratePerSecond: number, dt: number): number
	return math.max(0, value - ratePerSecond * dt)
end

--[[
	Which section of an ascending thresholds table a proportion falls in.
	thresholds {0, .1, .25, .5, 1} → sections 1..4 ([0,.1], (.1,.25], (.25,.5], (.5,1]).
	Generalized from HungerThirstManager's findThresholdSection: proportions are clamped
	into [0,1] and an exact boundary belongs to the LOWER section (deterministic, unlike
	the old sticky two-loop scan). Fires per-caller — no shared event (BUGS.md M11).
]]
function VitalsSim.findThresholdSection(thresholds: { number }, proportion: number): number
	local p = math.clamp(proportion, thresholds[1], thresholds[#thresholds])
	for i = 1, #thresholds - 1 do
		if p <= thresholds[i + 1] then
			return i
		end
	end
	return #thresholds - 1
end

export type StaminaStepResult = {
	stamina: number,
	cooldownRemaining: number,
}

--[[
	One frame/tick of continuous stamina simulation.
	- draining (sprinting while moving): stamina falls, and the regen cooldown re-arms.
	- otherwise the cooldown burns down; once expired, stamina regenerates to max.
	Everything clamps to [0, max] (BUGS.md M10).
]]
function VitalsSim.staminaStep(
	stamina: number,
	cooldownRemaining: number,
	config: { max: number, drainPerSecond: number, regenPerSecond: number, regenCooldown: number },
	dt: number,
	draining: boolean
): StaminaStepResult
	if draining and stamina > 0 then
		return {
			stamina = math.clamp(stamina - config.drainPerSecond * dt, 0, config.max),
			cooldownRemaining = config.regenCooldown,
		}
	end

	if cooldownRemaining > 0 then
		return {
			stamina = stamina,
			cooldownRemaining = math.max(0, cooldownRemaining - dt),
		}
	end

	return {
		stamina = math.clamp(stamina + config.regenPerSecond * dt, 0, config.max),
		cooldownRemaining = 0,
	}
end

-- Discrete stamina cost (jump, melee swing). Clamps at zero; the caller decides whether
-- an unaffordable action is allowed (ActionManager gating handles that client-side).
function VitalsSim.applyStaminaCost(stamina: number, cost: number): number
	return math.max(0, stamina - cost)
end

--[[
	Which movement mode the player actually GETS, given the mode they asked for.
	Sprint requires stamina in the pool; everything else passes through. The server
	looks the WalkSpeed number up from this — it never accepts a speed from the wire
	(BUGS.md C2).
]]
function VitalsSim.effectiveMovementMode(requestedMode: string, stamina: number): string
	if requestedMode == "Sprint" and stamina <= 0 then
		return "Default"
	end
	return requestedMode
end

--[[
	Reconcile client prediction against the replicated authoritative value: keep the
	smooth predicted value while it's plausibly close, snap to authority once they
	diverge past the tolerance (prediction and the 1 Hz server tick legitimately
	drift by a few points between attribute updates).
]]
function VitalsSim.reconcile(predicted: number, authoritative: number, tolerance: number): number
	if math.abs(predicted - authoritative) > tolerance then
		return authoritative
	end
	return predicted
end

return VitalsSim
