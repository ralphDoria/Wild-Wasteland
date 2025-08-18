--!strict
-----
-- General storage
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
-- Item System References
local ItemSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage
local References_ItemSystem = require(ItemSystem_ScriptStorage.References_ItemSystem)

--EXTERNAL CONTROLLERS
local AnimationManager = require("../Components/Shared/AnimationManager")
local SoundManager = require("../Components/Shared/SoundManager")
local ViewmodelManager = require("../Components/Shared/ViewmodelManager")
local ToolHighlightAndProxPromptManager = require("../Components/Shared/ToolHighlightAndProxPromptManager")
local ToolGuiManager = require("../Components/Shared/ToolGuiManager")
local ActionManager = require("../../ActionManagerSystem/ActionManager")
local ToolInfo = require("../Data/ToolInfo")
local CrosshairGuiManager = require("../Components/Shared/CrosshairManager")
local RunService = game:GetService("RunService")
-- local Trove = require(ReplicatedStorage.Packages.Trove)

local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables : {[string] : BindableEvent} = {
    ToggleEquip = ToolSystem_Storage.Shared:FindFirstChild("ToggleEquip", true),
    OnPickUp = ToolSystem_Storage.Shared.Bindables.OnPickUp,
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
    ImmediateUnequip = ToolSystem_Storage.Shared.Bindables.ImmediateUnequip,
}
local remotes: {[string] : RemoteEvent} = {
    ToggleToolCanCollide = ToolSystem_Storage.Shared.Remotes.ToggleToolCanCollide,
    DropTool = ToolSystem_Storage.Shared.Remotes.DropTool
}

local currentCharacter = player.Character or player.CharacterAdded:Wait()

type state = "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated" 
    | "Wearing" | "Unwearing" | "Worn"
    | "Dropping" | "Dropped" 
    | "Destroying" | "UpdatingCharacter"

export type ItemType = {
    tool : Tool,
    humanoid : Humanoid,
    soundManager : SoundManager.SoundManager,
    animManager : AnimationManager.AnimationManager,
    ViewmodelManager : ViewmodelManager.ViewmodelManager,
    ToolGuiManager : any,
    ToolHighlightAndProxPromptManager : ToolHighlightAndProxPromptManager.ToolHighlightAndProxPromptManager,
    crosshairGuiObject: CrosshairGuiManager.CrosshairObject,
    connections : {[string] : RBXScriptConnection},
    actionNames: {[string]: string},
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
        actionNames = {},
        State = "Unequipped"
    }

    self.actionNames.dropItem = "Drop Item" 
    Item.ChangeState(self, "Unequipped")
    SoundManager.storeSounds(tool.Name, ToolInfo.get(tool.Name).soundObjects)
    local toolAnims = ToolInfo.get(tool.Name).animObjects
    AnimationManager.LoadAnimations(currentAnimationManager, tool.Name, toolAnims)
    ViewmodelManager.AddTool(currentViewmodelManager, tool, toolAnims)

    -- warn(`SUCCESSFULLY INSTANTIATED {tool}`)
    return self
end

function Item.initialize(self : ItemType, equipping: () -> ()?, equipped: () -> ()?, unequipping: () -> ()?, unequipped: () -> ()?, onDropping : () -> ()?, onDropped : () -> ()?)

    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    Item.TrackAnimTrack(self, equipTrack, "Equip")

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
    self.connections.OnPickUp = bindables.OnPickUp.Event:Connect(function(key: Tool)  
        if key == self.tool then
            Item.ChangeState(self, "Unequipped")
        end
    end)
    self.connections.bindableDrop = bindables.DropToolBindable.Event:Connect(function(key: Tool) 
        if key == self.tool then
            print("Dropping")
            Item.drop(self)
        end
    end)
    self.connections.bindableImmediateUnequip = bindables.ImmediateUnequip.Event:Connect(function(key: Tool)  
        if key == self.tool then
            Item.immediateUnequip(self)
        end
    end)
end

--[[
    WARNING: THIS FUNCTION MAY YIELD. 
    This will create and update custom attributes of the tool called [trackName]Length 
    and [trackName]TimePosition. 
]]
function Item.TrackAnimTrack(self: ItemType, animTrack: AnimationTrack, trackName: string)
    while animTrack.Length == 0 do
        task.wait()
    end
    self.tool:SetAttribute(trackName .. "Length", animTrack.Length)
    self.tool:SetAttribute(trackName .. "TimePosition", animTrack.TimePosition)

    self.connections[trackName] = RunService.Heartbeat:Connect(function(a0: number)  
        if not animTrack.IsPlaying then return end

        if self.State ~= "Unequipped" and self.State ~= "Worn" then
            self.tool:SetAttribute(trackName .. "TimePosition", animTrack.TimePosition)
        end
    end)
end

function Item.equip(self: ItemType, equipping: () -> ()?, equipped: () -> ()?, onDropping : () -> ()?, onDropped : () -> ()?)
    Item.ChangeState(self, "Equipping")
    self.connections.dropEquippedToolOnDeath = self.humanoid.Died:Once(function(...: any)  
        Item.drop(self)
    end)
    ToolGuiManager.setTool(self.tool)
    ToolGuiManager.show()
    self.humanoid:EquipTool(self.tool)
    SoundManager.playSound("Server", SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    equipTrack.Priority = Enum.AnimationPriority.Action2
    local vmEquipTrack : AnimationTrack = currentViewmodelManager.animManager.animationTracks[self.tool.Name].equip
    Item.toggleDropBind(self, true, onDropping, onDropped)
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
    self.connections.dropEquippedToolOnDeath:Disconnect()
    Item.toggleDropBind(self, false)
    ToolGuiManager.hide()
    currentAnimationManager.animationTracks[self.tool.Name].idle:Stop()
    currentViewmodelManager.animManager.animationTracks[self.tool.Name].idle:Stop()
    local unequipSFX: Sound? = SoundManager.Sounds[self.tool.Name].unequip
    SoundManager.playSound("Server", if unequipSFX then unequipSFX else SoundManager.Sounds[self.tool.Name].equip :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0)
    local equipTrack : AnimationTrack = currentAnimationManager.animationTracks[self.tool.Name].equip
    equipTrack.Priority = Enum.AnimationPriority.Action
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
    equipTrack:Stop(0)
    if self.State == "Unequipping" or self.State == "Dropping" then
        self.humanoid:UnequipTools()
        Item.toggleDropBind(self, false)
        if unequipped then unequipped() end
        Item.ChangeState(self, "Unequipped")
    end
end

function Item.immediateUnequip(self: ItemType)
    if self.State == "Unequipped" then return end
    
    for _, v in self.actionNames do
        if ActionManager.isBinded(v) then
            ActionManager.unbindAction(v)
        end 
    end
    AnimationManager.StopAllAnimsForTool(currentAnimationManager, self.tool)
    AnimationManager.StopAllAnimsForTool(self.ViewmodelManager.animManager, self.tool)
    Item.ChangeState(self, "Unequipped")
    ToolGuiManager.hide()
end

function Item.ChangeState(self: ItemType, state: state)
    self.tool:SetAttribute("State", state)
    self.State = state
end

function Item.drop(self : ItemType, onDropping: () -> ()?, onDropped : () -> ()?)
    if self.State == "Idle" or self.State == "Equipping" or self.State == "Unequipped" or self.State == "Wearing" or self.State == "Unwearing" then
        Item.ChangeState(self, "Dropping")
        for _, v in self.actionNames do
            if ActionManager.isBinded(v) then
                ActionManager.unbindAction(v)
            end 
        end
        if onDropping then
            onDropping()
        end
        if self.State ~= "Unequipped" then
            AnimationManager.StopAllAnimsForTool(currentAnimationManager, self.tool)
            AnimationManager.StopAllAnimsForTool(self.ViewmodelManager.animManager, self.tool)
        end
        remotes.DropTool:FireServer(self.tool)
        Item.ChangeState(self, "Dropped")
        if onDropped then
            onDropped()
        end
        ToolGuiManager.hide()
        warn(`DROPPED ITEM`)
    end
end

function Item.toggleDropBind(self : ItemType, toggle : boolean, onDropping: () -> ()?, onDropped : () -> ()?)
    if toggle then
        ActionManager.bindAction(
            self.actionNames.dropItem, 
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
        ActionManager.unbindAction(self.actionNames.dropItem)
    end
end

function Item.Destroy(self : ItemType, childObjectCleanupMethod: () -> ())
    Item.ChangeState(self, "Destroying")
    ToolHighlightAndProxPromptManager.Destroy(self.ToolHighlightAndProxPromptManager)
    --animManager internal data
    ViewmodelManager.removeTool(self.ViewmodelManager, self.tool)
    for connectionName, v in self.connections do
        v:Disconnect()
    end
    childObjectCleanupMethod()
    table.clear(self)
    warn(`DESTROYED ITEM`)
end

return Item