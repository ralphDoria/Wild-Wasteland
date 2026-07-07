--!strict
--[[
	Server-authoritative vitals simulation (Tier 3 rewrite — replaces the client-side decay
	loops in HungerThirstManager and the exploitable hungerThirstDamage remote, BUGS.md
	C9/M12/M13; Batch V2 adds stamina + movement authority, killing the arbitrary-WalkSpeed
	remote, C2).

	Plain-data state per player, ticked by ONE Heartbeat accumulator at
	VitalsConfig.tickInterval (these stats change slowly — no per-player threads, no
	per-frame work). Replication is player attributes ("Hunger"/"Thirst"/"Stamina"): free
	join-in-progress state, and the client views just listen to GetAttributeChangedSignal
	(the client StaminaManager keeps a local prediction and reconciles to the attribute).

	Movement: clients send an INTENT ("Default"|"Sprint"|"Crouch") via the MovementIntent
	remote (MovementAndStaminaSystem_Server/Main.server.lua); the server looks the WalkSpeed
	up in Data/Config itself and gates Sprint on server-side stamina. Sprint only drains
	while the server observes horizontal movement, matching the old client behavior. Jump
	cost is charged on Humanoid.StateChanged -> Jumping; melee swing cost is charged by
	MeleeReceiver on the (validated) Swing remote.

	VitalsService.restore is the single mutation surface for consumables/buffs (Batch V3
	wires ConsumableReceiver into it) — the vitals twin of NPCDamageAPI.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VitalsSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage
local VitalsConfig = require(VitalsSystem_ScriptStorage.Data.VitalsConfig)
local VitalsSim = require(VitalsSystem_ScriptStorage.Sim.VitalsSim)
-- Movement speeds (Sprint/Crouch/Default). Shared with the client, but the server reads
-- the numbers itself — the wire only ever carries the mode name.
local MovementConfig = require(VitalsSystem_ScriptStorage.Data.Config)

-- The stats this service decays and replicates. Attribute name -> config.
local decayConfigs: { [string]: VitalsConfig.DecayStatConfig } = {
	Hunger = VitalsConfig.Hunger,
	Thirst = VitalsConfig.Thirst,
}

type PlayerVitals = {
	-- attribute-replicated numbers: Hunger, Thirst, Stamina
	stats: { [string]: number },
	staminaCooldown: number,
	-- what the player asked for (validated mode name)
	movementMode: string,
	-- what WalkSpeed the server last applied (mode name), to avoid redundant writes
	appliedMode: string,
}

local states: { [Player]: PlayerVitals } = {}
local initialized = false

local VitalsService = {}

local function setStat(player: Player, state: PlayerVitals, statName: string, value: number)
	if state.stats[statName] == value then
		return
	end
	state.stats[statName] = value
	player:SetAttribute(statName, value)
end

local function getAliveHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

-- Sets the humanoid's WalkSpeed from the player's movement mode, downgrading Sprint to
-- Default while server stamina is empty. Only writes when the effective mode changed.
local function applyMovementSpeed(state: PlayerVitals, humanoid: Humanoid)
	local effectiveMode = VitalsSim.effectiveMovementMode(state.movementMode, state.stats.Stamina)
	if effectiveMode == state.appliedMode then
		return
	end
	local speed = MovementConfig.speed[effectiveMode]
	if not speed then
		return
	end
	humanoid.WalkSpeed = speed
	state.appliedMode = effectiveMode
end

-- Fresh character, full stats — matches the old per-life client objects.
local function resetState(player: Player)
	local state = states[player]
	if not state then
		state = {
			stats = {},
			staminaCooldown = 0,
			movementMode = "Default",
			appliedMode = "Default",
		}
		states[player] = state
	end
	for statName, config in decayConfigs do
		setStat(player, state, statName, config.max)
	end
	setStat(player, state, "Stamina", VitalsConfig.Stamina.max)
	state.staminaCooldown = 0
	state.movementMode = "Default"
	state.appliedMode = "Default" -- a fresh humanoid spawns at the default WalkSpeed
end

-- Is the character actually moving horizontally? Sprint only drains while moving,
-- matching the old client-side isMovingHorizontally gate.
local function isMovingHorizontally(character: Model): boolean
	local root = character.PrimaryPart
	if not root then
		return false
	end
	local velocity = root.AssemblyLinearVelocity
	return Vector2.new(velocity.X, velocity.Z).Magnitude > VitalsConfig.Stamina.movingSpeedThreshold
end

local function tick(dt: number)
	for player, state in states do
		local character = player.Character
		if not character then
			continue -- no decay while unspawned; CharacterAdded resets to full
		end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or humanoid.Health <= 0 then
			continue -- no decay while dead
		end

		-- Hunger/Thirst decay + starvation
		local starvationDps = 0
		for statName, config in decayConfigs do
			local newValue = VitalsSim.decay(state.stats[statName], config.decayPerSecond, dt)
			setStat(player, state, statName, newValue)
			if newValue <= 0 then
				starvationDps += config.starvationDamagePerSecond
			end
		end

		if starvationDps > 0 then
			-- TakeDamage so spawn-protection ForceFields still block it, as before
			humanoid:TakeDamage(starvationDps * dt)
		end

		-- Stamina: drain while sprinting AND moving, otherwise cooldown -> regen.
		local draining = state.movementMode == "Sprint" and isMovingHorizontally(character)
		local result = VitalsSim.staminaStep(
			state.stats.Stamina,
			state.staminaCooldown,
			VitalsConfig.Stamina,
			dt,
			draining
		)
		setStat(player, state, "Stamina", result.stamina)
		state.staminaCooldown = result.cooldownRemaining

		-- Stamina hitting zero (or regenerating from it) can flip sprint eligibility.
		applyMovementSpeed(state, humanoid)
	end
end

-- Restore (or, with negative amounts, drain) replicated stats — Hunger/Thirst/Stamina.
-- Clamped to [0, max]; unknown stat names are ignored. Callers (ConsumableReceiver in
-- Batch V3) handle Health themselves — it lives on the Humanoid, not here.
function VitalsService.restore(player: Player, restores: { [string]: number })
	local state = states[player]
	if not state then
		return
	end
	for statName, amount in restores do
		local config = decayConfigs[statName]
		local max = if config then config.max elseif statName == "Stamina" then VitalsConfig.Stamina.max else nil
		if max and type(amount) == "number" and amount == amount then
			setStat(player, state, statName, math.clamp(state.stats[statName] + amount, 0, max))
		end
	end
end

--[[
	Validated movement intent (Batch V2, kills C2). `mode` must be a key of
	Data/Config.speed ("Default"/"Sprint"/"Crouch"); the server sets the sender's OWN
	humanoid WalkSpeed from config — no humanoid, no number accepted from the wire.
]]
function VitalsService.setMovementIntent(player: Player, mode: string)
	local state = states[player]
	if not state or type(mode) ~= "string" or MovementConfig.speed[mode] == nil then
		return
	end
	state.movementMode = mode
	local humanoid = getAliveHumanoid(player)
	if humanoid then
		applyMovementSpeed(state, humanoid)
	end
end

-- Discrete stamina cost (jump / melee swing), charged server-side. Re-arms the regen
-- cooldown like any drain, and re-evaluates sprint eligibility (cost may empty the pool).
function VitalsService.applyStaminaCost(player: Player, cost: number)
	local state = states[player]
	if not state or type(cost) ~= "number" or cost ~= cost or cost <= 0 then
		return
	end
	setStat(player, state, "Stamina", VitalsSim.applyStaminaCost(state.stats.Stamina, cost))
	state.staminaCooldown = VitalsConfig.Stamina.regenCooldown
	local humanoid = getAliveHumanoid(player)
	if humanoid then
		applyMovementSpeed(state, humanoid)
	end
end

function VitalsService.init()
	if initialized then
		return
	end
	initialized = true

	local function onCharacterAdded(player: Player, character: Model)
		resetState(player)
		-- Jump cost is charged where the jump actually happens: the humanoid state
		-- machine (replicated from the owning client). The client's ActionManager
		-- gating still decides whether the jump is ALLOWED; this just keeps the
		-- authoritative pool honest.
		task.spawn(function()
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not humanoid or not humanoid:IsA("Humanoid") then
				return
			end
			humanoid.StateChanged:Connect(function(_oldState, newState)
				if newState == Enum.HumanoidStateType.Jumping then
					VitalsService.applyStaminaCost(player, VitalsConfig.Stamina.jumpCost)
				end
			end)
		end)
	end

	local function onPlayerAdded(player: Player)
		resetState(player)
		player.CharacterAdded:Connect(function(character)
			onCharacterAdded(player, character)
		end)
		if player.Character then
			onCharacterAdded(player, player.Character)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)

	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt: number)
		accumulated += dt
		if accumulated >= VitalsConfig.tickInterval then
			tick(accumulated)
			accumulated = 0
		end
	end)
end

return VitalsService
