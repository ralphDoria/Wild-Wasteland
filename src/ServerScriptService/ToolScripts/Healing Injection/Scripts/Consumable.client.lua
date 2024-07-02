local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ConsumableController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("ConsumableController"))

--[[
    use composition to make a unique HealingInjection class that uses Consumable as a blueprint/superclass
]]

local consumable : Tool = script.Parent.Parent
local controller = ConsumableController.new(consumable)