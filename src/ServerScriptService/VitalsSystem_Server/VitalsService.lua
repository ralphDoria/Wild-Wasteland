--!strict
--[[
	Server-authoritative vitals simulation (Tier 3 rewrite — replaces the client-side decay
	loops in HungerThirstManager and the exploitable hungerThirstDamage remote, BUGS.md
	C9/M12/M13).

	Plain-data state per player, ticked by ONE Heartbeat accumulator at
	VitalsConfig.tickInterval (these stats change slowly — no per-player threads, no
	per-frame work). Replication is player attributes ("Hunger"/"Thirst"): free join-in-
	progress state, and the client views just listen to GetAttributeChangedSignal.

	VitalsService.restore is the single mutation surface for consumables/buffs (Batch V3
	wires ConsumableReceiver into it) — the vitals twin of NPCDamageAPI.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VitalsSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage
local VitalsConfig = require(VitalsSystem_ScriptStorage.Data.VitalsConfig)
local VitalsSim = require(VitalsSystem_ScriptStorage.Sim.VitalsSim)

-- The stats this service decays and replicates. Attribute name -> config.
local decayConfigs: { [string]: VitalsConfig.DecayStatConfig } = {
	Hunger = VitalsConfig.Hunger,
	Thirst = VitalsConfig.Thirst,
}

type PlayerVitals = { [string]: number }

local states: { [Player]: PlayerVitals } = {}
local initialized = false

local VitalsService = {}

local function setStat(player: Player, state: PlayerVitals, statName: string, value: number)
	if state[statName] == value then
		return
	end
	state[statName] = value
	player:SetAttribute(statName, value)
end

-- Fresh character, full stats — matches the old per-life client objects.
local function resetState(player: Player)
	local state: PlayerVitals = states[player] or {}
	states[player] = state
	for statName, config in decayConfigs do
		setStat(player, state, statName, config.max)
	end
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

		local starvationDps = 0
		for statName, config in decayConfigs do
			local newValue = VitalsSim.decay(state[statName], config.decayPerSecond, dt)
			setStat(player, state, statName, newValue)
			if newValue <= 0 then
				starvationDps += config.starvationDamagePerSecond
			end
		end

		if starvationDps > 0 then
			-- TakeDamage so spawn-protection ForceFields still block it, as before
			humanoid:TakeDamage(starvationDps * dt)
		end
	end
end

-- Restore (or, with negative amounts, drain) decay stats. Clamped to [0, max]; unknown
-- stat names are ignored. Callers (ConsumableReceiver in Batch V3) handle Health
-- themselves — it lives on the Humanoid, not here.
function VitalsService.restore(player: Player, restores: { [string]: number })
	local state = states[player]
	if not state then
		return
	end
	for statName, amount in restores do
		local config = decayConfigs[statName]
		if config and type(amount) == "number" and amount == amount then
			setStat(player, state, statName, math.clamp(state[statName] + amount, 0, config.max))
		end
	end
end

function VitalsService.init()
	if initialized then
		return
	end
	initialized = true

	local function onPlayerAdded(player: Player)
		resetState(player)
		player.CharacterAdded:Connect(function()
			resetState(player)
		end)
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
