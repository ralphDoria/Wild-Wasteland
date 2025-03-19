--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
--EXTERNAL CONTROLLERS
local AnimationManager = require("../Components/AnimationManager")
local SoundManager = require("../Components/SoundManager")
local ViewmodelManager = require("../Components/ViewmodelManager")
local RobloxStateMachine = require(ReplicatedStorage.Packages.RobloxStateMachine)
local ToolInfo = require("../ToolInfo")

local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables : {[string] : BindableEvent} = {
    ToggleEquip = ToolSystem_Storage.Shared:FindFirstChild("ToggleEquip", true)
}
local remotes: {[string] : RemoteEvent} = {
    ToggleToolCanCollide = ToolSystem_Storage.Shared.Remotes.ToggleToolCanCollide
}

local currentCharacter = player.Character or player.CharacterAdded:Wait()

export type ItemType = {
    tool : Tool,
    humanoid : Humanoid,
    soundManager : SoundManager.SoundManager,
    animManager : AnimationManager.AnimationManager,
    ViewmodelManager : ViewmodelManager.ViewmodelManager,
    finiteStateMachine : ModuleScript?,
    connections : {[string] : RBXScriptConnection},
    State : "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated"
}

local currentAnimationManager = AnimationManager.new(currentCharacter)
local currentViewmodelManager = ViewmodelManager.new(workspace.CurrentCamera:WaitForChild("viewModel"))

local Item = {}

--[[
    Makes this tool usable for the humanoid's current character
]]
function Item.new(tool : Tool, humanoid : Humanoid) : ItemType
    local self : ItemType = {
        tool = tool,
        humanoid = humanoid,
        soundManager = SoundManager,
        animManager = currentAnimationManager,
        ViewmodelManager = currentViewmodelManager :: any, --viewmodelController will handle viewmodel instance reference
        finiteStateMachine = RobloxStateMachine :: any,
        connections = {},
        State = "Unequipped"
    }

    Item.ChangeState(self, "Unequipped")
    SoundManager.storeSounds(tool.Name, ToolInfo.get(tool.Name).soundObjects)
    local toolAnims = ToolInfo.get(tool.Name).animObjects
    AnimationManager.LoadAnimations(currentAnimationManager, tool.Name, toolAnims)
    ViewmodelManager.AddTool(currentViewmodelManager, tool, toolAnims)

    return self
end

function Item.initialize(self : ItemType, equipping: () -> ()?, equipped: () -> ()?, unequipping: () -> ()?, unequipped: () -> ()?)
    self.connections.ToggleEquip = bindables.ToggleEquip.Event:Connect(function(key : Tool, toggle: boolean)
        if key == self.tool then
            if toggle then
                Item.equip(self, equipping, equipped)
            else
                Item.unequip(self, unequipping, unequipped) 
            end 
        end
    end)
    self.connections.ToggleToolCanCollide = self.tool.AncestryChanged:Connect(function(child: Instance, parent: Instance?)  
        if parent and parent:FindFirstChildOfClass("Humanoid") then
            remotes.ToggleToolCanCollide:FireServer(self.tool:FindFirstChild("ToolModel"), false)
        else
            remotes.ToggleToolCanCollide:FireServer(self.tool:FindFirstChild("ToolModel"), true)
        end
    end)
end

function Item.equip(self: ItemType, equipping: () -> ()?, equipped: () -> ()?)
    Item.ChangeState(self, "Equipping")
    if equipping then equipping() end
    self.humanoid:EquipTool(self.tool)
    SoundManager.playSound("Server", SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    local vmEquipTrack : AnimationTrack = currentViewmodelManager.animManager.animationTracks[self.tool.Name].equip
    if equipTrack.IsPlaying then
        equipTrack:AdjustSpeed(1)
        vmEquipTrack:AdjustSpeed(1)
    else
        equipTrack:Play(0.1, 1, 1)
        vmEquipTrack:Play(0.1, 1, 1)
    end
    equipTrack.Stopped:Wait()
    if self.State == "Equipping" then
        Item.ChangeState(self, "Idle")
        if equipped then equipped() end
        currentAnimationManager.animationTracks[self.tool.Name].idle:Play()
        currentViewmodelManager.animManager.animationTracks[self.tool.Name].idle:Play()
    end
end

function Item.unequip(self: ItemType, unequipping: () -> ()?, unequipped: () -> ()?)
    Item.ChangeState(self, "Unequipping")
    if unequipping then unequipping() end
    currentAnimationManager.animationTracks[self.tool.Name].idle:Stop()
    currentViewmodelManager.animManager.animationTracks[self.tool.Name].idle:Stop()
    SoundManager.playSound("Server", SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    local vmEquipTrack : AnimationTrack = currentViewmodelManager.animManager.animationTracks[self.tool.Name].equip
    if equipTrack.IsPlaying then
        equipTrack:AdjustSpeed(-1)
        vmEquipTrack:AdjustSpeed(-1)
    else
        equipTrack:Play(0.1, 1, -1)
        vmEquipTrack:Play(0.1, 1, -1)
    end
    equipTrack.Stopped:Wait()
    if self.State == "Unequipping" then
        Item.ChangeState(self, "Unequipped")
        if unequipped then unequipped() end
        self.humanoid:UnequipTools()
    end
end

function Item.ChangeState(self: ItemType, state: "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated")
    self.tool:SetAttribute("State", state)
    self.State = state
end

function Item.drop(self : ItemType)
end

function Item.destroy(self : ItemType)
end

return Item