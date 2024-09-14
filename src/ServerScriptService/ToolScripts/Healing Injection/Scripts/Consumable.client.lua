local ConsumableController = require(game:GetService("ReplicatedStorage"):FindFirstChild("ConsumableController", true))

--[[
    use composition to make a unique HealingInjection class that uses Consumable as a blueprint/superclass
]]

local consumable : Tool = script.Parent.Parent
local controller = ConsumableController.new(consumable)