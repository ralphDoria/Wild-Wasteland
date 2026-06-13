-- General Services and PLayer References
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local SpawnAndDeathSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.SpawnAndDeathSystem_ScriptStorage
local SpawnAndDeathManager = require(SpawnAndDeathSystem_ScriptStorage.SpawnAndDeathManager)
local SpawnAndDeathSystem_Storage = ReplicatedStorage.SpawnAndDeathManager_Storage
local rfnFolder = SpawnAndDeathSystem_Storage.RemoteFunctions
local rfn = {
   MoveCharacterToSpawn = rfnFolder.MoveCharacterToSpawn:: RemoteFunction
}

-- Utility Modules
local ZonePLus = require(ReplicatedStorage.Packages.ZonePlus)

-- Instances
local zoneArea_protectedSpawnArea = workspace.Zones.ProtectedSpawnArea.zoneArea

-- Initializing protected spawn zone
local protectedSpawnZone = ZonePLus.new(zoneArea_protectedSpawnArea)
protectedSpawnZone.playerEntered:Connect(function(player: Player)
    local character = player.Character
    SpawnAndDeathManager.applyCharacterProtocolTitleScreen(character)
end)
protectedSpawnZone.playerExited:Connect(function(player: Player)
    local character = player.Character
    SpawnAndDeathManager.cleanUpCharacterProtocolTitleScreen(character)
end)

rfn.MoveCharacterToSpawn.OnServerInvoke = function(player, spawnPointCFrame: CFrame)
    local character: Model = player.Character or player.CharacterAdded:Wait()
    character:PivotTo(spawnPointCFrame)
    return
end
