--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
--EXTERNAL CONTROLLERS
local AnimationManager = require("../Components/Shared/AnimationManager")
local SoundManager = require("../Components/Shared/SoundManager")
local ViewmodelManager = require("../Components/Shared/ViewmodelManager")
local ToolHighlightAndProxPromptManager = require("../Components/Shared/ToolHighlightAndProxPromptManager")
local ToolGuiManager = require("../Components/Shared/ToolGuiManager")
local ActionManager = require("../../ActionManagerSystem/ActionManager")
local ToolInfo = require("../Data/ToolInfo")
local CrosshairGuiManager = require("../Components/Shared/CrosshairManager")
-- local Trove = require(ReplicatedStorage.Packages.Trove)

local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables : {[string] : BindableEvent} = {
    ToggleEquip = ToolSystem_Storage.Shared:FindFirstChild("ToggleEquip", true),
    OnPickUp = ToolSystem_Storage.Shared.Bindables.OnPickUp
}
local remotes: {[string] : RemoteEvent} = {
    ToggleToolCanCollide = ToolSystem_Storage.Shared.Remotes.ToggleToolCanCollide,
    DropTool = ToolSystem_Storage.Shared.Remotes.DropTool
}

local currentCharacter = player.Character or player.CharacterAdded:Wait()

type state = "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated" | "Dropping" | "Dropped" | "Destroying" | "UpdatingCharacter"

export type ItemType = {
    tool : Tool,
    humanoid : Humanoid,
    soundManager : SoundManager.SoundManager,
    animManager : AnimationManager.AnimationManager,
    ViewmodelManager : ViewmodelManager.ViewmodelManager,
    ToolGuiManager : any,
    ToolHighlightAndProxPromptManager : ToolHighlightAndProxPromptManager.ToolHighlightAndProxPromptManager,
    finiteStateMachine : ModuleScript?,
    crosshairGuiObject: CrosshairGuiManager.CrosshairObject,
    connections : {[string] : RBXScriptConnection},
    State : state
}

local currentAnimationManager = AnimationManager.new(currentCharacter)
local currentViewmodelManager = ViewmodelManager.new(workspace.CurrentCamera:WaitForChild("viewModel"))
local crosshairGuiObject = CrosshairGuiManager.new()
CrosshairGuiManager.toggleCrosshairLines(crosshairGuiObject, false)


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
        ToolGuiManager = ToolGuiManager,
        ToolHighlightAndProxPromptManager = ToolHighlightAndProxPromptManager.new(tool),
        crosshairGuiObject = crosshairGuiObject,
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

function Item.initialize(self : ItemType, equipping: () -> ()?, equipped: () -> ()?, unequipping: () -> ()?, unequipped: () -> ()?, onDropping : () -> ()?, onDropped : () -> ()?)

    self.connections.ToggleEquip = bindables.ToggleEquip.Event:Connect(function(key : Tool, toggle: boolean)
        if key == self.tool then
            if toggle then
                Item.equip(self, equipping, equipped, onDropping, onDropped)
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
            ViewmodelManager.toggleViewmodelToolVisibility(currentViewmodelManager, self.tool, false)
            --Proximity Prompt and highlight
        end
    end)
    self.connections.OnPickUp = bindables.OnPickUp.Event:Connect(function()  
        Item.ChangeState(self, "Unequipped")
    end)
end

function Item.equip(self: ItemType, equipping: () -> ()?, equipped: () -> ()?, onDropping : () -> ()?, onDropped : () -> ()?)
    Item.ChangeState(self, "Equipping")
    ToolGuiManager.setTool(self.tool)
    ToolGuiManager.show()
    self.humanoid:EquipTool(self.tool)
    SoundManager.playSound("Server", SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    local vmEquipTrack : AnimationTrack = currentViewmodelManager.animManager.animationTracks[self.tool.Name].equip
    Item.toggleDropBind(self, true, onDropping, onDropped)
    CrosshairGuiManager.toggleEnable(crosshairGuiObject)
    if equipping then equipping() end
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
        currentAnimationManager.animationTracks[self.tool.Name].idle:Play()
        currentViewmodelManager.animManager.animationTracks[self.tool.Name].idle:Play()
        if equipped then equipped() end
    end
end

function Item.unequip(self: ItemType, unequipping: () -> ()?, unequipped: () -> ()?)
    Item.ChangeState(self, "Unequipping")
    Item.toggleDropBind(self, false)
    ToolGuiManager.hide()
    currentAnimationManager.animationTracks[self.tool.Name].idle:Stop()
    currentViewmodelManager.animManager.animationTracks[self.tool.Name].idle:Stop()
    SoundManager.playSound("Server", SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    local vmEquipTrack : AnimationTrack = currentViewmodelManager.animManager.animationTracks[self.tool.Name].equip
    CrosshairGuiManager.ForceDisable(crosshairGuiObject)
    if unequipping then unequipping() end
    if equipTrack.IsPlaying then
        equipTrack:AdjustSpeed(-1)
        vmEquipTrack:AdjustSpeed(-1)
    else
        equipTrack:Play(0.1, 1, -1)
        vmEquipTrack:Play(0.1, 1, -1)
    end
    equipTrack.Stopped:Wait()
    if self.State == "Unequipping" or self.State == "Dropping" then
        Item.ChangeState(self, "Unequipped")
        self.humanoid:UnequipTools()
        Item.toggleDropBind(self, false)
        if unequipped then unequipped() end
    end
end

function Item.ChangeState(self: ItemType, state: state)
    self.tool:SetAttribute("State", state)
    self.State = state
end

function Item.drop(self : ItemType, onDropping: () -> ()?, onDropped : () -> ()?)
    if self.State == "Idle" or self.State == "Equipping" then
        Item.ChangeState(self, "Dropping")
        Item.toggleDropBind(self, false)
        CrosshairGuiManager.ForceDisable(crosshairGuiObject) 
        if onDropping then
            onDropping()
        end
        AnimationManager.StopAllAnimsForTool(currentAnimationManager, self.tool)
        AnimationManager.StopAllAnimsForTool(self.ViewmodelManager.animManager, self.tool)
        remotes.DropTool:FireServer(self.tool)
        Item.ChangeState(self, "Dropped")
        if onDropped then
            onDropped()
        end
        ToolGuiManager.hide()
    end
end

function Item.toggleDropBind(self : ItemType, toggle : boolean, onDropping: () -> ()?, onDropped : () -> ()?)
    if toggle then
        ActionManager.bindAction(
            "Drop Item", 
            function(): (() -> (), () -> (), () -> ())  
                local function onActivated()
                end

                local function onDeactivated()
                    Item.drop(self, onDropping, onDropped)
                end

                local function onUnbind()
                    
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.KeyCode.X, 
            Enum.KeyCode.ButtonX, 
            4, 
            nil, 
            nil, 
            "rbxassetid://108041751673485")
    else
        ActionManager.unbindAction("Drop Item")
    end
end

function Item.updateCharacter()
    
end

function Item.Destroy(self : ItemType, childObjectCleanupMethod: () -> ())
    warn("running this ")
    Item.ChangeState(self, "Destroying")
    ToolHighlightAndProxPromptManager.Destroy(self.ToolHighlightAndProxPromptManager)
    --animManager internal data
    ViewmodelManager.removeTool(self.ViewmodelManager, self.tool)
    for _, v in self.connections do
        v:Disconnect()
    end
    childObjectCleanupMethod()
    warn("clearing table")
    table.clear(self)
end

return Item