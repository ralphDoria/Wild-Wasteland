local Players = game:GetService("Players")

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))

local dataStores = {}
--initialize data store table
for _, stat in playerStatsInfo.getAll() do
    dataStores[stat.name] = DataStoreService:GetDataStore(stat.name)
end

Players.PlayerAdded:Connect(function(player)
    for _, stat in playerStatsInfo.getAll() do
        local success, statValue = pcall(function()
            dataStores[stat.name]:GetAsync(player.UserId)
        end)
        if success then
            print("---retreived " .. stat.name .. " value: " .. tostring(statValue))
            player:SetAttribute(stat.name, if statValue then statValue else 30)
        end
    end
    --player:SetAttribute("StatsLoaded", true)
end)

Players.PlayerRemoving:Connect(function(player)
    for _, stat in playerStatsInfo.getAll() do
        local success, errorMessage = pcall(function()
            dataStores[stat.name]:SetAsync(player.UserId, 2)
        end)
        if success then
            print("---successfully saved " .. 2 .. " " .. stat.name)
        else
            print("---" .. stat.name .. " saving error message: " .. errorMessage)
        end
    end
end)  