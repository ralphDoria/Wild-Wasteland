--!nonstrict
--[[
	Entry point + lifecycle wiring for the home-base ↔ wasteland loop. Orders the services so a
	joining player gets: profile loaded → base region built (rehydrated) → placed in their
	bunker → storage view pushed; and a leaving player: base snapshotted → profile saved+released
	→ region freed → travel state cleaned up.

	SCAFFOLD STATUS: wiring is complete against the service interfaces, but the whole system is
	inert against the live place until (a) the persistence lock is finished/ProfileStore adopted,
	and (b) the place content exists (ServerStorage.HomeBaseTemplates.<template> + named anchors,
	workspace.<WastelandArrival>). Missing pieces warn and no-op rather than crash. It also does
	NOT yet replace RandomSpawnPoints / the C5 MoveCharacterToSpawn remote — do that when turning
	the system on (see docs/HOME_BASE_LOOP_RESEARCH.md build order).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.Remotes)

local PlayerProfileService = require(script.Parent.PlayerProfileService)
local HomeBaseService = require(script.Parent.HomeBaseService)
local TravelService = require(script.Parent.TravelService)
local BaseStorageService = require(script.Parent.BaseStorageService)

local remoteMap = Remotes.initServer()
TravelService.init(remoteMap)
BaseStorageService.init(remoteMap)

-- Build a player's base once we have both a loaded profile and a spawned character.
local function onCharacterAdded(player: Player, _character: Model)
	if not PlayerProfileService.get(player) then
		return -- profile still loading (or failed); PlayerAdded handles ordering
	end
	local region = HomeBaseService.createBaseFor(player)
	if not region then
		return -- place content missing; already warned
	end
	TravelService.placeInBunker(player)
	BaseStorageService.onBaseReady(player)
end

local function onPlayerAdded(player: Player)
	local profile = PlayerProfileService.load(player)
	if not profile then
		player:Kick("Your saved data could not be loaded. Please rejoin.") -- avoid overwriting good data
		return
	end
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	if player.Character then
		onCharacterAdded(player, player.Character)
	end
end

local function onPlayerRemoving(player: Player)
	HomeBaseService.releaseBaseFor(player) -- snapshots base into the profile first
	PlayerProfileService.release(player) -- save + drop the session lock
	TravelService.cleanup(player)
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
	PlayerProfileService.releaseAll()
end)
