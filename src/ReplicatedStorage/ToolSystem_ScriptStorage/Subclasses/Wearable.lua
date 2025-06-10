--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Item = require("./../Superclasses/Item")
local ItemState = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.ToolStateMachine.ItemState)
local ActionManager = require("../../ActionManagerSystem/ActionManager")
local WearableCategory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.WearableCategory)
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    ToggleWear = ToolSystem_Storage.Wearable.Remotes.ToggleWear,
    OnWorn = ToolSystem_Storage.Wearable.Remotes.OnWorn,
    CreateWornItemStorage = ToolSystem_Storage.Wearable.Remotes.CreateWornItemStorage
}
local bindables: {[string] : BindableEvent} = {
    ToggleWear = ToolSystem_Storage.Wearable.Bindables.ToggleWear
}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolCatalog: Folder = ReplicatedStorage:FindFirstChild("ToolCatalog", true)
export type WearableType = Item.ItemType & {
    originalAccessory: Accessory,
    thisAccessory: Accessory,
    WearSpeed: number,
    WearableCategory: WearableCategory.WearableCategoryType,
    onWearing: () -> (),
    onUnwearing: () -> (),
    applyWornEffects: () -> (),
    removeWornEffects: () -> ()
}
local FilledSlotsTracker = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.FilledSlotsTracker)
local Slot = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Slot)
local player = game:GetService("Players").LocalPlayer

remotes.CreateWornItemStorage:FireServer(WearableCategory.ValidWearableCategories)
local WornItems: Folder = player.Backpack:WaitForChild("WornItems")

local Wearable = {}

function Wearable.new(tool: Tool, humanoid: Humanoid)
    local self = Item.new(tool, humanoid):: WearableType
    
    local thisWearableCategory = tool:GetAttribute("WearableCategory")
    WearableCategory.typeCheck(thisWearableCategory)

    -- instance variables inherited from Item
    self.actionNames.wearUnwear = "Wear/Unwear"

    -- instance variables from Wearable
    local toolFolder = ToolCatalog:FindFirstChild(tool.Name, true)
    if toolFolder == nil then
        error("Folder for " .. tool.Name .. " not found in ToolCatalog" )
    end
    self.originalAccessory = toolFolder:FindFirstChildWhichIsA("Accessory", true):: Accessory
    self.thisAccessory = self.tool:FindFirstChildWhichIsA("Accessory", true):: Accessory
    self.WearableCategory = tool:GetAttribute("WearableCategory"):: WearableCategory.WearableCategoryType
    self.WearSpeed = 1

    return self
end

local function toggleWearBind(self : WearableType, toggle : boolean)
    if toggle then
        ActionManager.bindAction(
            self.actionNames.wearUnwear, 
            function(): (() -> (), () -> (), () -> ())  

                local function onActivated()
                    local slot = FilledSlotsTracker.GetSlotFromTool(self.tool)
                    if slot then
                        local category: Folder = WornItems:FindFirstChild(self.WearableCategory):: Folder
                        local wornToolOfCategory = category:FindFirstChildOfClass("Tool")
                        if wornToolOfCategory == nil then
                            Slot.SwapSlots(slot, FilledSlotsTracker.WearableSlots[self.WearableCategory])
                        else
                            -- @TODO display ui warning indicator by cursor stating "gear slot already filled"
                        end
                    else
                        warn(`Can't wear{self.tool}, slot not found`)
                    end
                end

                local function onDeactivated()
                    
                end

                local function onUnbind()
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.UserInputType.MouseButton1,
            Enum.KeyCode.ButtonR2, 
            3, 
            nil, 
            nil, 
            "rbxassetid://115384682565092")
    else
        ActionManager.unbindAction(self.actionNames.wearUnwear)
    end
end

function Wearable.initialize(self: WearableType, onWearing: () -> (), onUnwearing: () -> (), appyWornEffects: () -> (), removeWornEffects: () -> ())

    local wearTrack = self.animManager.animationTracks[self.tool.Name].wear
    Item.TrackAnimTrack(self, wearTrack, "Wear")

    self.onWearing = onWearing
    self.onUnwearing = onUnwearing
    self.applyWornEffects = appyWornEffects
    self.removeWornEffects = removeWornEffects

    Item.initialize(
        self,
        function()  --onEquipping
        end, 
        function() --onEquipped
            toggleWearBind(self, true)
        end,
        function() --onUnequipping
            toggleWearBind(self, false) 
        end,
        function() --onUnequipped()
        end, 
        function() --onDropping()
            toggleWearBind(self, false)
        end,
        function() --onDropped()
        end
    )
    self.connections.wearTrackOverlapped = wearTrack:GetMarkerReachedSignal("overlapped"):Connect(function(...: any)  
        if self.State == "Wearing" then
            for _, v in self.thisAccessory:GetDescendants() do
                if v:IsA("BasePart") then
                    remotes.ToggleWear:FireServer(true, self.humanoid.Parent, self.originalAccessory, self.thisAccessory, self.tool, self.WearableCategory)
                    self.applyWornEffects()
                end
            end
        elseif self.State == "Unwearing" then
            for _, v in self.thisAccessory:GetDescendants() do
                if v:IsA("BasePart") then
                    remotes.ToggleWear:FireServer(false, self.humanoid.Parent, self.originalAccessory, self.thisAccessory, self.tool, self.WearableCategory)
                    self.removeWornEffects()
                end
            end
        end
    end)
    self.connections.draggedToWear = bindables.ToggleWear.Event:Connect(function(key: Tool, toggle: boolean)  
        if key == self.tool then
            if toggle then
                Wearable.wear(self)
            else
                Wearable.unwear(self)
            end
        end
    end)
end

function Wearable.onWorn(self: WearableType)
    if self.State == "Worn" then
        self.ToolGuiManager.hide()
        -- remotes.OnWorn:FireServer(self.tool, self.WearableCategory)
        for _, v in self.actionNames do
            if ActionManager.isBinded(v) then
                ActionManager.unbindAction(v)
            end
        end
    end
end

function Wearable.wear(self: WearableType)
    if self.State == "Idle" or self.State == "Unwearing" then
        Item.ChangeState(self, "Wearing")
        self.onWearing()
        local wearTrack = self.animManager.animationTracks[self.tool.Name].wear
        local vmWearTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].wear
        local idleTrack = self.animManager.animationTracks[self.tool.Name].idle
        local vmIdleTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].idle
        if wearTrack.IsPlaying then
            wearTrack:AdjustSpeed(1)
            vmWearTrack:AdjustSpeed(1)
        else
            wearTrack:Play(0.1, 1, 1)
            vmWearTrack:Play(0.1, 1, 1)
        end
        idleTrack:Stop()
        vmIdleTrack:Stop()
        wearTrack.Stopped:Wait()
        if self.State:: ItemState.ItemState == "Wearing" then -- have to do a recheck here because this is an cancellable asynchronous operation
            -- warn("running onWorn")
            Item.ChangeState(self, "Worn")
            Wearable.onWorn(self)
            self.tool:SetAttribute("IsWorn", true)
        end
    end
end

function Wearable.unwear(self: WearableType)
    if self.State == "Worn" or self.State == "Wearing" then
        Item.ChangeState(self, "Unwearing")
        self.onUnwearing()
        local wearTrack = self.animManager.animationTracks[self.tool.Name].wear
        local vmWearTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].wear
        local idleTrack = self.animManager.animationTracks[self.tool.Name].idle
        local vmIdleTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].idle
        if wearTrack.IsPlaying then
            wearTrack:AdjustSpeed(-1)
            vmWearTrack:AdjustSpeed(-1)
        else
            wearTrack:Play(0.1, 1, -1)
            vmWearTrack:Play(0.1, 1, -1)
        end
        idleTrack:Stop()
        vmIdleTrack:Stop()
        wearTrack.Stopped:Wait()
        if self.State:: ItemState.ItemState == "Unwearing" then -- have to do a recheck here because this is an cancellable asynchronous operation
            idleTrack:Play()
            vmIdleTrack:Play()
            Item.ChangeState(self, "Idle")
        end
    end
end


function Wearable.Destroy(self: WearableType, childObjectCleanupMethod: () -> ())
    Item.Destroy(self, function()
        toggleWearBind(self, false)
        childObjectCleanupMethod()
    end)
end

return Wearable