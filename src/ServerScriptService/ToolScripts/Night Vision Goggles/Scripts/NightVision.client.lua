--[[
local NightVisionGoggles = require(game:GetService("ReplicatedStorage"):FindFirstChild("NVGogglesClass", true))

local tool : Tool = script:FindFirstAncestorOfClass("Tool") --this script should be parented inside a tool
print(tool.Parent)
local nvGoggles = NightVisionGoggles.new(tool)
]]
