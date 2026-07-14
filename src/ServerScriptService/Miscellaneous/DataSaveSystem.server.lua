local Players = game:GetService("Players")

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))

local dataStores = {}
--initialize data store table (getPersisted = pickup stats + progression stats like XP)
for _, stat in playerStatsInfo.getPersisted() do
    dataStores[stat.name] = DataStoreService:GetDataStore(stat.name)
end

Players.PlayerAdded:Connect(function(player)
    for _, stat in playerStatsInfo.getPersisted() do
        local success, statValue = pcall(function()
            return dataStores[stat.name]:GetAsync(player.UserId)
        end)
        if success then
            --print("---retreived " .. stat.name .. " value: " .. tostring(statValue))
            player:SetAttribute(stat.name, if statValue then statValue else 0)
        end
    end
    player:SetAttribute("StatsLoaded", true)
end)

local function savePlayerData(player)
    for _, stat in playerStatsInfo.getPersisted() do
        local success, errorMessage = pcall(function()
            dataStores[stat.name]:SetAsync(player.UserId, player:GetAttribute(stat.name))
        end)
        if not success then
            warn("[DataSaveSystem] Failed to save " .. stat.name .. " for " .. player.Name .. ": " .. tostring(errorMessage))
        end
    end
end

Players.PlayerRemoving:Connect(function(player)
    savePlayerData(player)
end)

-- Ensure data is flushed on server shutdown/update so PlayerRemoving saves are not lost.
game:BindToClose(function()
    local remaining = 0
    for _, player in Players:GetPlayers() do
        remaining += 1
        task.spawn(function()
            savePlayerData(player)
            remaining -= 1
        end)
    end
    -- Wait for the spawned saves to finish (bounded so we never block shutdown indefinitely).
    local elapsed = 0
    while remaining > 0 and elapsed < 25 do
        elapsed += task.wait()
    end
end)