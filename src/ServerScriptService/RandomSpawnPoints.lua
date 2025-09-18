--!strict
local Players = game:GetService("Players")
local spawnPointsFolder = workspace:FindFirstChild("spawnPoints", true):: Folder
local spawnPoints = spawnPointsFolder:GetChildren()
local function getRandomSpawnPoint()
    local randomIndex = math.random(1, #spawnPoints)
    return spawnPoints[randomIndex]
end

for _, player in Players:GetPlayers() do
    player.CharacterAdded:Connect(function(_: Model) 
        player.RespawnLocation = getRandomSpawnPoint()
    end)
end
