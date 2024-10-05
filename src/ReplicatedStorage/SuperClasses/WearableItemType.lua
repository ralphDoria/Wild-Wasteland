--! This is a parent class

--CONSTANTS
local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    ACTION_DROP_TOOL = "Dropped"
}
--LOCAL VARIABLES
local player = game:GetService("Players").LocalPlayer
--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
--REMOTE EVENTS
local rev_playSound = ReplicatedStorage.Tools.Shared:FindFirstChild("PlaySound", true)
local rev_dropTool = ReplicatedStorage.Tools.Shared:FindFirstChild("DropTool", true)

local Wearable = {}
Wearable.__index = Wearable
local ItemTemplate = require(ReplicatedStorage:FindFirstChild("ItemTemplate", true))
setmetatable(Wearable, ItemTemplate)

function Wearable.new(tool : Tool)
    local self = ItemTemplate.new(tool)
    --[[
    self.animObjects.takeOff = 
    ]]
    self.animObjects.putOn = tool.Anims:FindFirstChild("putOn", true)
    self.wearing = false
    --The intialize method would usually be called here, but only the final child class will call initialize
    return self
end

function Wearable:initialize(subclassObject)
    ItemTemplate:initialize(subclassObject)
    --any additional connnections can be added under here
end

function Wearable:equip(subclassObject, tableOfFunctions, altAnimInfo)
    ItemTemplate:equip(subclassObject, tableOfFunctions, altAnimInfo)
end

function Wearable:PutOn(subclassObject)
    subclassObject.charAnimController.animationTracks.putOn.Ended:Once(function()
        subclassObject.tool:SetAttribute("isWearing", true)
    end)
    subclassObject.charAnimController.animationTracks.putOn:Play()
    subclassObject.vmController.animationController.animationTracks.putOn:Play()
end

function Wearable:TakeOff(subclassObject)
end

--[[
    !!!
    Equip and unequip methods are inherited from the ItemTemplate parent class
]]

function Wearable:activate(subclassObject)
    --empty for now
end


return Wearable