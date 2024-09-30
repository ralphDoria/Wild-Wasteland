--! This is like a grandfather class if each of the item types are parent classes

--CONSTANTS
local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    ACTION_DROP_TOOL = "Dropped"
}
--LOCAL VARIABLES
local Players = game:GetService("Players")
local player = game:GetService("Players").LocalPlayer
--SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
--EXTERNAL CONTROLLERS
local AnimationController = require(ReplicatedStorage:FindFirstChild("AnimationController", true))
local ViewModelController = require(ReplicatedStorage:FindFirstChild("ViewModelController", true))
--REMOTE EVENTS
local rev_playSound = ReplicatedStorage.Tools.Shared:FindFirstChild("PlaySound", true)
local rev_dropTool = ReplicatedStorage.Tools.Shared:FindFirstChild("DropTool", true)

local ItemTemplate = {}
ItemTemplate.__index = ItemTemplate

function ItemTemplate.new(tool : Tool)
    local toolAnimsFolder = tool:WaitForChild("Anims")
    if not toolAnimsFolder then
        warn(tool.Name .. "is missing Anims Folder")
    end

    local self = {
        tool = tool,
        currentCharacter = nil,
        __type = "Item",
        animObjects = { --These are the fundamental animations, more can be added in whatever child class uses this parent class
            equip = toolAnimsFolder:FindFirstChild("equip", true),
            idle = toolAnimsFolder:FindFirstChild("idle", true),
            --activate = toolAnimsFolder:FindFirstChild("activate", true),
        },
        soundObjects = { equip = tool.BodyAttach.Sounds.equip},
        VMController = ViewModelController,
        AnimController = AnimationController, 
        --[[
            The field variable above may not be needed because a new currentCharacterAnimationController is only controlled & destroyed
            here in this parent class
        ]]
        viewModelController = nil, --this will be set in the final child class, when all animations are given
        currentCharacterAnimationController = nil, --this will be set later when the tool is equipped/unequipped
        canActivate = false,
        equipped = false,
        connections = {}
    }

    setmetatable(self, ItemTemplate)
    --The intialize method would usually be called here, but only the final child class will call initialize
    return self
end

--[[
]]
function ItemTemplate:initialize(subclassObject)
    table.insert(
        subclassObject.connections,
        subclassObject.tool.Equipped:Connect(function()
            subclassObject:equip()
        end)
    )
    table.insert(
        subclassObject.connections,
        subclassObject.tool.Unequipped:Connect(function()
            subclassObject:unequip()
        end)
    )
    table.insert(
        subclassObject.connections,
        player.Character.Torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
            if subclassObject:isFirstPerson() then
                if subclassObject.equipped then
                    subclassObject.viewModelController:enable()
                end
            else
                if subclassObject.equipped then
                    subclassObject.viewModelController:disable()
                end
            end
        end)
    )
end

--[[
    FINAL
    _____
    This method is final, no need to be overriden/modified in
    child classes.
]]
function ItemTemplate:isFirstPerson()
    return player.Character.Torso.LocalTransparencyModifier >= 1
end

--[[
    The equip function for every weapon is mostly the same.
]]
function ItemTemplate:equip(subclassObject, tableOfFunctions)
    self.currentCharacter = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    if subclassObject == nil then
        subclassObject = self
    end
    if subclassObject:isFirstPerson() then
        subclassObject.viewModelController:enable()
    else
        subclassObject.viewModelController:disable()
    end
    subclassObject.viewModelController:equipTool()

    rev_playSound:FireServer(subclassObject.soundObjects.equip, subclassObject.tool.BodyAttach, 0)
    subclassObject.equipped = true
    subclassObject.currentCharacter = player.Character
    local diedConnection
    diedConnection = subclassObject.currentCharacter.Humanoid.Died:Connect(function()
        print("died connection")
        if tableOfFunctions.deathProcedure then
            tableOfFunctions.deathProcedure()
        end
        subclassObject:unequip()
        rev_dropTool:FireServer(subclassObject.tool)
    end)
    subclassObject.tool:GetPropertyChangedSignal("Parent"):Once(function()
        local toolWasUnequipped = subclassObject.tool.Parent ~= subclassObject.currentCharacter
        if toolWasUnequipped then
            diedConnection:Disconnect()
        end
    end)
    if subclassObject.currentCharacter:GetAttribute(string.gsub(subclassObject.tool.Name, " ", "") .. "AnimsLoaded") == nil then
		subclassObject.currentCharacter:SetAttribute(string.gsub(subclassObject.tool.Name, " ", "") .. "AnimsLoaded", true)
		subclassObject.currentCharacterAnimationController = AnimationController.new(subclassObject.currentCharacter:FindFirstChild("Animator", true), subclassObject.animObjects)
	end
    --player:GetMouse().Icon = self.tool:GetAttribute("Cursor")

    subclassObject.currentCharacterAnimationController.animationTracks.equip:Play()
    subclassObject.viewModelController.animationController.animationTracks.equip:Play()
    subclassObject.currentCharacterAnimationController.animationTracks.equip.Stopped:Wait()
    if subclassObject.equipped then --checking this because during the equip animation, players can unequip the tool, causing a bug
        subclassObject.equipped = true
        subclassObject.viewModelController.toolEquipped = true
        ContextActionService:BindAction(Constants.ACTION_DROP_TOOL, function(actionName, inputState, _inputObject)
            if actionName == Constants.ACTION_DROP_TOOL and inputState == Enum.UserInputState.Begin then
                subclassObject:unequip()
                rev_dropTool:FireServer(subclassObject.tool, false)
            end
        end, true, Enum.KeyCode.X)
        subclassObject.currentCharacterAnimationController.animationTracks.idle:Play()
        subclassObject.viewModelController.animationController.animationTracks.idle:Play()
        subclassObject.canActivate = true
        if tableOfFunctions.forceWear then
            tableOfFunctions.forceWear(subclassObject)
        end
    end
end

--[[
    The activate function is somewhat different for each weapon
]]
function ItemTemplate:activate()
end

--[[
    The unequip function for every weapon is mostly the same.
]]
function ItemTemplate:unequip(subclassObject)
    if subclassObject == nil then
        subclassObject = self
    end
    subclassObject.equipped = false
    subclassObject.viewModelController.toolEquipped = false
    subclassObject.viewModelController:disable()
    subclassObject.viewModelController:unequipTool()

    subclassObject.equipped = false
    ContextActionService:UnbindAction(Constants.ACTION_DROP_TOOL)
	player:GetMouse().Icon = ""
	subclassObject.canActivate = false
	for _, animTrack : AnimationTrack in subclassObject.currentCharacter.Humanoid.Animator:GetPlayingAnimationTracks() do
		for _, anim : Animation in subclassObject.animObjects do
            if animTrack.Animation == anim then
                animTrack:Stop()
            end
        end
	end
    subclassObject.viewModelController:stopAllViewModelAnimations()
	subclassObject.currentCharacterAnimationController:destroy()
	subclassObject.currentCharacter:SetAttribute(string.gsub(subclassObject.tool.Name, " ", "") .. "AnimsLoaded", nil)
end

function ItemTemplate:destroy()
end

return ItemTemplate