local NightVisionGoggles = require(game:GetService("ReplicatedStorage"):FindFirstChild("NightVisionGoggles", true))

local tool : Tool = script:FindFirstAncestorOfClass("Tool") --this script should be parented inside a tool
local nvGoggles = NightVisionGoggles.new(tool)
