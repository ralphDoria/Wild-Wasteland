--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local player = game:GetService("Players").LocalPlayer
--EXTERNAL CONTROLLERS
local AnimationManager = require("../Components/Shared/AnimationManager")
local SoundManager = require("../Components/Shared/SoundManager")
local ViewmodelManager = require("../Components/Shared/ViewmodelManager")
local ToolHighlightAndProxPromptManager = require("../Components/Shared/ToolHighlightAndProxPromptManager")
local ToolGuiManager = require("../Components/Shared/ToolGuiManager")
local RobloxStateMachine = require(ReplicatedStorage.Packages.RobloxStateMachine)
local ToolInfo = require("../Data/ToolInfo")

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

export type ItemType = {
    tool : Tool,
    humanoid : Humanoid,
    soundManager : SoundManager.SoundManager,
    animManager : AnimationManager.AnimationManager,
    ViewmodelManager : ViewmodelManager.ViewmodelManager,
    ToolGuiManager : ToolGuiManager.ToolGuiManager,
    ToolHighlightAndProxPromptManager : ToolHighlightAndProxPromptManager.ToolHighlightAndProxPromptManager,
    finiteStateMachine : ModuleScript?,
    connections : {[string] : RBXScriptConnection},
    State : "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated" | "Dropping" | "Dropped"
}

local currentAnimationManager = AnimationManager.new(currentCharacter)
local currentViewmodelManager = ViewmodelManager.new(workspace.CurrentCamera:WaitForChild("viewModel"))
local currentToolGuiManager = ToolGuiManager.new()

local ActionNameToKeycodesMapping : {[string] : {Enum.UserInputType | Enum.KeyCode}} = {
    ["Drop"] = {
        Enum.KeyCode.X,
        Enum.KeyCode.ButtonX
    }
}

local ActionNameToLayoutOrderMapping : {[string] : number} = {
    ["Drop"] = 0
}

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
        ToolGuiManager = currentToolGuiManager,
        ToolHighlightAndProxPromptManager = ToolHighlightAndProxPromptManager.new(tool),
        finiteStateMachine = RobloxStateMachine :: any,
        connections = {},
        State = "Unequipped"
    }

    for actionName, keycodes in ActionNameToKeycodesMapping do
        ToolGuiManager.CreateInputGui(currentToolGuiManager, tool, actionName, ActionNameToKeycodesMapping[actionName], ActionNameToLayoutOrderMapping[actionName])
    end 
    Item.ChangeState(self, "Unequipped")
    SoundManager.storeSounds(tool.Name, ToolInfo.get(tool.Name).soundObjects)
    local toolAnims = ToolInfo.get(tool.Name).animObjects
    AnimationManager.LoadAnimations(currentAnimationManager, tool.Name, toolAnims)
    ViewmodelManager.AddTool(currentViewmodelManager, tool, toolAnims)

    return self
end

function Item.initialize(self : ItemType, equipping: () -> ()?, equipped: () -> ()?, unequipping: () -> ()?, unequipped: () -> ()?, onDropped : () -> ()?)

    self.connections.ToggleEquip = bindables.ToggleEquip.Event:Connect(function(key : Tool, toggle: boolean)
        if key == self.tool then
            if toggle then
                Item.equip(self, equipping, equipped, onDropped)
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

function Item.equip(self: ItemType, equipping: () -> ()?, equipped: () -> ()?, onDropped : () -> ()?)
    Item.ChangeState(self, "Equipping")
    ToolGuiManager.toggleToolGuiVisibility(currentToolGuiManager, self.tool, true)
    self.humanoid:EquipTool(self.tool)
    SoundManager.playSound("Server", SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    local vmEquipTrack : AnimationTrack = currentViewmodelManager.animManager.animationTracks[self.tool.Name].equip
    Item.toggleDropBind(self, true, onDropped)
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
    ToolGuiManager.toggleToolGuiVisibility(currentToolGuiManager, self.tool, false)
    currentAnimationManager.animationTracks[self.tool.Name].idle:Stop()
    currentViewmodelManager.animManager.animationTracks[self.tool.Name].idle:Stop()
    SoundManager.playSound("Server", SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    local vmEquipTrack : AnimationTrack = currentViewmodelManager.animManager.animationTracks[self.tool.Name].equip
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

function Item.ChangeState(self: ItemType, state: "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated" | "Dropping" | "Dropped")
    self.tool:SetAttribute("State", state)
    self.State = state
end

function Item.drop(self : ItemType, onDropped : () -> ()?)
    if self.State == "Idle" or self.State == "Equipping" then
        Item.ChangeState(self, "Dropping")
        AnimationManager.StopAllAnimsForTool(currentAnimationManager, self.tool)
        AnimationManager.StopAllAnimsForTool(self.ViewmodelManager.animManager, self.tool)
        remotes.DropTool:FireServer(self.tool)
        Item.ChangeState(self, "Dropped")
        if onDropped then
            onDropped()
        end
        ToolGuiManager.toggleToolGuiVisibility(currentToolGuiManager, self.tool, false)
    end
end

function Item.toggleDropBind(self : ItemType, toggle : boolean, onDropped : () -> ()?)
    local function handleAction(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
        if inputState == Enum.UserInputState.Begin then
            Item.drop(self, onDropped)
        end
        return Enum.ContextActionResult.Sink
    end
    if toggle then
        ContextActionService:BindAction("Drop", handleAction, true, unpack(ActionNameToKeycodesMapping["Drop"]))
    else
        ContextActionService:UnbindAction("Drop")
    end
end

function Item.destroy(self : ItemType)
end

return Item