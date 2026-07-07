--!strict
--[[
	Vitals server entry point (Tier 3 rewrite).

	- Boots VitalsService (server-authoritative hunger/thirst — see VitalsService.lua).
	- The old hungerThirstDamage handler is GONE (BUGS.md C9/M13): the server simulates
	  starvation itself, so the Studio-side remote is now inert if a client fires it.
	- RespawnPlayerCharacter is gated (C16): only honored for a player who is actually
	  dead, at a bounded rate — no more free combat-escape respawns.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VitalsConfig = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.Data.VitalsConfig)
local VitalsService = require(script.Parent.VitalsService)

VitalsService.init()

local VitalsSystem_Storage = ReplicatedStorage:FindFirstChild("VitalsSystem_Storage", true)
assert(VitalsSystem_Storage, "VitalsSystem_Storage not found in ReplicatedStorage")
local respawnRemote = VitalsSystem_Storage:FindFirstChild("RespawnPlayerCharacter", true) :: RemoteEvent

local lastRespawnRequest: { [Player]: number } = {}
Players.PlayerRemoving:Connect(function(player: Player)
	lastRespawnRequest[player] = nil
end)

respawnRemote.OnServerEvent:Connect(function(player: Player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			return -- alive senders don't get a respawn (C16)
		end
	end

	local now = os.clock()
	local last = lastRespawnRequest[player]
	if last and now - last < VitalsConfig.respawnRequestCooldown then
		return
	end
	lastRespawnRequest[player] = now

	player:LoadCharacter()
end)
