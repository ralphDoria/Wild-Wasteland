--!strict
local Players = game:GetService("Players")
local spawnPointsFolder = workspace:FindFirstChild("spawnPoints", true):: Folder
local spawnPoints = spawnPointsFolder:GetChildren()
local function getRandomSpawnPoint(): SpawnLocation
    local randomIndex = math.random(1, #spawnPoints)
    return spawnPoints[randomIndex]:: SpawnLocation
end

local testMainSpawnPoint: SpawnLocation
for _, v in spawnPoints do
    if v.Name == "testMain" then
        testMainSpawnPoint = v:: BasePart
    end
end

print(if testMainSpawnPoint then "testMainSpawnPoint found" else "testMainSpawnPoint not found")

local function setSpawnPoint(player: Player)
    player.RespawnLocation = if testMainSpawnPoint then testMainSpawnPoint else getRandomSpawnPoint()
    player.CharacterAdded:Connect(function(_: Model) 
        if not testMainSpawnPoint then
            player.RespawnLocation = getRandomSpawnPoint()
        else
            player.RespawnLocation = testMainSpawnPoint
        end
    end)
end

for _, player in Players:GetPlayers() do
    setSpawnPoint(player)
end



Players.PlayerAdded:Connect(function(player: Player)  
    setSpawnPoint(player)
end)