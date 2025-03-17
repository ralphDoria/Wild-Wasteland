--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
--EXTERNAL CONTROLLERS
local AnimationManager = require("../Components/AnimationManager")
local ViewmodelController = require("../Components/ViewModelController")
local RobloxStateMachine = require(ReplicatedStorage.Packages.RobloxStateMachine)
local ToolInfo = require("../ToolInfo")

local remotes : {RemoteEvent} = {
    playSound = ReplicatedStorage.Tools.Shared.Remotes.PlaySound,
    drop = ReplicatedStorage.Tools.Shared.Remotes.DropTool
}

local currentCharacter = player.Character or player.CharacterAdded:Wait()

warn("Creating AnimationManager object. This should only run once.")
local currentAnimationManager = AnimationManager.new(currentCharacter)

player.CharacterAdded:Connect(function(character : Model)  
    if not currentCharacter or currentCharacter.Parent == nil then
        warn("Creating new AnimationManager due to CharacterAdded.")
        currentCharacter = character
        AnimationManager.destroy(currentAnimationManager)
        currentAnimationManager = AnimationManager.new(currentCharacter) 
    end
end)

export type ItemType = {
    tool : Tool,
    humanoid : Humanoid,
    sounds : { Sound? },
    animManager : AnimationManager.AnimationManager,
    viewmodelController : ModuleScript?,
    finiteStateMachine : ModuleScript?,
    connections : { RBXScriptConnection? },
    State : "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated"
}

local Item = {}

--[[
    Makes this tool usable for the humanoid's current character
]]
function Item.new(tool : Tool, humanoid : Humanoid) : ItemType
    local self : ItemType = {
        tool = tool,
        humanoid = humanoid,
        sounds = {},
        animManager = currentAnimationManager,
        viewmodelController = ViewmodelController :: any, --viewmodelController will handle viewmodel instance reference
        finiteStateMachine = RobloxStateMachine :: any,
        connections = {},
        State = "Unequipped"
    }

    AnimationManager.LoadAnimations(currentAnimationManager, tool.Name, ToolInfo.get(tool.Name).animObjects)

    return self
end

function Item.equip(self : ItemType)
    self.State = "Equipping"
    self.humanoid:EquipTool(self.tool)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    if equipTrack.IsPlaying then
        equipTrack:AdjustSpeed(1)
    else
        equipTrack:Play(0.1, 1, 1)
    end
    equipTrack.Stopped:Wait()
    if self.State == "Equipping" then
        self.State = "Idle"
        currentAnimationManager.animationTracks[self.tool.Name].idle:Play()
    end
end

function Item.unequip(self : ItemType, unequipping : () -> ()?, unequipped : () -> ()?)
    self.State = "Unequipping"
    if unequipping then unequipping() end
    currentAnimationManager.animationTracks[self.tool.Name].idle:Stop()
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    if equipTrack.IsPlaying then
        equipTrack:AdjustSpeed(-1)
    else
        equipTrack:Play(0.1, 1, -1)
    end
    equipTrack.Stopped:Wait()
    if self.State == "Unequipping" then
        self.State = "Unequipped"
        if unequipped then unequipped() end
        self.humanoid:UnequipTools()
    end
end

function Item.drop(self : ItemType)
end

function Item.destroy(self : ItemType)
end

return Item