--NightVisionGoggles will inherit from the Wearable class
local Players = game:GetService("Players")
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

local NightVisionGoggles = {}
NightVisionGoggles.__index = NightVisionGoggles
local Wearable = require(game:GetService("ReplicatedStorage"):FindFirstChild("WearableItemType", true))
setmetatable(NightVisionGoggles, Wearable)

function NightVisionGoggles.new(tool : Tool)
    local self = Wearable.new(tool)
    --[[
    LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE,
    LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE,
    LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE

    You need to find a way to give this class (the final child class) access to ViewModelController and AnimationController because those
    need to be created here. I feel close to getting this inheritance thing down
    ]]
    self.viewModelController = self.VMController.new(workspace.CurrentCamera:WaitForChild("viewModel"), tool, self.animObjects, hrp)
    setmetatable(self, NightVisionGoggles)
    self:intialize()
    return self
end 

function NightVisionGoggles:intialize()
    Wearable:initialize(self)
    --in here will be events specific to the night vision goggles
end

function NightVisionGoggles:activate()
    --this is where the actual night vision funcationality comes in, which is unique to this class only
    --[[
        This'll make adding items of any class type sooo much easier because I don't have to write boilerplate code. This makes me love OOP.
        Consider composition over inheritance because I heard inheritance can get messy.
    ]]
end

return NightVisionGoggles

