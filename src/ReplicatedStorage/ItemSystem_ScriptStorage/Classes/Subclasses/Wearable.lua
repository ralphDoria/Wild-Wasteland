--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

local Type_Item = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.ToolStateMachine.Type_Item)
local Type_Equipment = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.CharacterSection.Components.Type_Equipment)

local remotes = {
    ToggleWear = References_ItemSystem.ItemSystem_Storage.Wearable.Remotes.ToggleWear:: RemoteEvent,
    OnWorn = References_ItemSystem.ItemSystem_Storage.Wearable.Remotes.OnWorn:: RemoteEvent,
    MakeAccessoryVisibleOnDeath = References_ItemSystem.ItemSystem_Storage.Wearable.Remotes.MakeAccessoryVisibleOnDeath:: RemoteEvent
}
local bindables = {
    ToggleWear = References_ItemSystem.ItemSystem_Storage.Wearable.Bindables.ToggleWear:: BindableEvent
}

-- Parent Class
local Item = require("./../Superclasses/Item")

local ToolCatalog: Folder = ReplicatedStorage:FindFirstChild("ToolCatalog", true)
export type WearableType = Item.ItemType & {
    originalAccessory: Accessory,
    thisAccessory: Accessory,
    WearSpeed: number,
    WearableCategory: Type_Equipment.EquipmentCategory,
    onWearing: () -> (),
    onUnwearing: () -> (),
    applyWornEffects: () -> (),
    removeWornEffects: () -> ()
}
local Slot = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Slot)
local player = game:GetService("Players").LocalPlayer

local WornItems: Folder

local Wearable = {}

function Wearable.new(tool: Tool)
    WornItems = player.Backpack:WaitForChild("WornItems")
    local self = Item.new(tool):: WearableType
    
    local thisWearableCategory = tool:GetAttribute("WearableCategory")
    Type_Equipment.typeCheck(thisWearableCategory)

    -- instance variables inherited from Item
    self.actionNames.wearUnwear = "Wear/Unwear"

    -- instance variables from Wearable
    local toolFolder = ToolCatalog:FindFirstChild(tool.Name, true)
    if toolFolder == nil then
        error("Folder for " .. tool.Name .. " not found in ToolCatalog" )
    end
    self.originalAccessory = toolFolder:FindFirstChildWhichIsA("Accessory", true):: Accessory
    self.thisAccessory = self.tool:FindFirstChildWhichIsA("Accessory", true):: Accessory
    self.WearableCategory = tool:GetAttribute("WearableCategory"):: Type_Equipment.EquipmentCategory
    self.WearSpeed = 1

    return self
end

local function toggleWearBind(self : WearableType, toggle : boolean)
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
            self.actionNames.wearUnwear, 
            function(): (() -> (), () -> (), () -> ())  

                local function onActivated()
                    local toolSlot = Slot.toolToObjectMap[self.tool]
                    if toolSlot then
                        local category: Folder = WornItems:FindFirstChild(self.WearableCategory):: Folder
                        local wornToolOfCategory = category:FindFirstChildOfClass("Tool")
                        if wornToolOfCategory == nil then
                            warn("Equipping wearable via equip is currently disabled")
                            -- have to incorporate ActionHandler here to implement equip wearable via click
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
        References_ItemSystem.ActionManager.unbindAction(self.actionNames.wearUnwear)
    end
end

function Wearable.initialize(self: WearableType, onWearing: () -> (), onUnwearing: () -> (), appyWornEffects: () -> (), removeWornEffects: () -> ())

    local wearTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].wear
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
    self.trove:Connect(wearTrack:GetMarkerReachedSignal("overlapped"), function(...: any)  
        if self.State == "Wearing" then
            for _, v in self.thisAccessory:GetDescendants() do
                if v:IsA("BasePart") then
                    remotes.ToggleWear:FireServer(true, References_ItemSystem.humanoid.Parent, self.originalAccessory, self.thisAccessory, self.tool, self.WearableCategory)
                    self.applyWornEffects()
                end
            end
        elseif self.State == "Unwearing" then
            for _, v in self.thisAccessory:GetDescendants() do
                if v:IsA("BasePart") then
                    remotes.ToggleWear:FireServer(false, References_ItemSystem.humanoid.Parent, self.originalAccessory, self.thisAccessory, self.tool, self.WearableCategory)
                    self.removeWornEffects()
                end
            end
        end
    end)
    self.trove:Connect(bindables.ToggleWear.Event, function(key: Tool, toggle: boolean)  
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
        References_ItemSystem.ItemHUD.hide()
        -- remotes.OnWorn:FireServer(self.tool, self.WearableCategory)
        for _, v in self.actionNames do
            if References_ItemSystem.ActionManager.isBinded(v) then
                References_ItemSystem.ActionManager.unbindAction(v)
            end
        end
    end
end

function Wearable.wear(self: WearableType)
    if self.State == "Idle" or self.State == "Unwearing" then
        Item.ChangeState(self, "Wearing")
        self.onWearing()
        local wearTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].wear
        local vmWearTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].wear
        local idleTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].idle
        local vmIdleTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].idle
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

        if self.State:: Type_Item.ItemState == "Wearing" then -- have to do a recheck here because this is an cancellable asynchronous operation
            -- warn("Entering worn state")
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
        local wearTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].wear
        local vmWearTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].wear
        local idleTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].idle
        local vmIdleTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].idle
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
        if self.State:: Type_Item.ItemState == "Unwearing" then -- have to do a recheck here because this is an cancellable asynchronous operation
            idleTrack:Play()
            vmIdleTrack:Play()
            Item.ChangeState(self, "Idle")
        end
    end
end


function Wearable.Destroy(self: WearableType, childObjectCleanupMethod: () -> ())
    Item.Destroy(self, function()
        remotes.MakeAccessoryVisibleOnDeath:FireServer(self.thisAccessory)
        toggleWearBind(self, false)
        childObjectCleanupMethod()
    end)
end

return Wearable