--!strict

local Item = require("./../Superclasses/Item")
local WearableCategory = require(game:GetService("StarterPlayer").StarterCharacterScripts.RojoManaged_SCS.RevampedInventorySystem_Client.Components.WearableCategory)
local ActionManager = require("../../ActionManagerSystem/ActionManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    ToggleWear = ToolSystem_Storage.Wearable.Remotes.ToggleWear,
}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolCatalog: Folder = ReplicatedStorage:FindFirstChild("ToolCatalog", true)
export type WearableType = Item.ItemType & {
    originalAccessory: Accessory,
    WearSpeed: number,
    WearableCategory: WearableCategory.WearableCategoryType,
    applyWornEffects: () -> (),
    removeWornEffects: () -> ()
}

local Wearable = {}

function Wearable.new(tool: Tool, humanoid: Humanoid)
    local self = Item.new(tool, humanoid):: WearableType
    
    local valid = false
    local thisWearableCategory = tool:GetAttribute("WearableCategory")
    for _, v in WearableCategory do
        if thisWearableCategory == v then
            valid = true
        end
    end
    if not valid then
        error(tostring(thisWearableCategory) .. " is not a valid WearableCategory attribute")
    end

    -- instance variables inherited from Item
    self.actionNames.wearUnwear = "Wear/Unwear"

    -- instance variables from Wearable
    local toolFolder = ToolCatalog:FindFirstChild(tool.Name, true)
    if toolFolder == nil then
        error("Folder for " .. tool.Name .. " not found in ToolCatalog" )
    end
    self.originalAccessory = toolFolder:FindFirstChildWhichIsA("Accessory", true):: Accessory
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
                    Wearable.wear(self)
                end

                local function onDeactivated()
                    if self.State ~= "Worn" then
                        Wearable.unwear(self)
                    end
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

function Wearable.initialize(self: WearableType, appyWornEffects: () -> (), removeWornEffects: () -> ())

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
end

function Wearable.wear(self: WearableType)
    if self.State == "Idle" or self.State == "Worn" or self.State == "Unwearing" then
        Item.ChangeState(self, "Wearing")
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
        if self.State == "Wearing" then
            Item.ChangeState(self, "Worn")
            remotes.ToggleWear:FireServer(true, self.humanoid.Parent, self.originalAccessory)
            self.applyWornEffects()
        end
    end
end

function Wearable.unwear(self: WearableType)
    if self.State == "Worn" or self.State == "Wearing" then
        Item.ChangeState(self, "Unwearing")
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
        if self.State == "Unwearing" then
             idleTrack:Play()
            vmIdleTrack:Play()
            Item.ChangeState(self, "Idle")
            remotes.ToggleWear:FireServer(false, self.humanoid.Parent, self.originalAccessory)
            self.removeWornEffects()
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