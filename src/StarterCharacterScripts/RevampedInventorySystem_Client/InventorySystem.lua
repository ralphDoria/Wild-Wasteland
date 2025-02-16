local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local backpack = player.Backpack

local InventorySystem = {}

function InventorySystem.init()

end

return InventorySystem