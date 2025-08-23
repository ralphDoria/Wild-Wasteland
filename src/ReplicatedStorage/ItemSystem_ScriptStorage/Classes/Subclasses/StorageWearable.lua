local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

local bindables = {
    DropToolBindable = References_ItemSystem.ItemSystem_Storage.Shared.Bindables.DropToolBindable:: BindableEvent,
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local SlotGroup = require(InventoryScriptStorage.Components.Slot.SlotGroup)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)

-- Parent Class
local Wearable = require("./Wearable")

type StorageWearableObject = Wearable.WearableType & {
    Space: number, -- number of storage slots it'll the wearer
    slotGroup: SlotGroup.object?,
    associatedSlotGroup: ObjectValue,
    lootPrompt: ProximityPrompt,
    isUpdating: boolean
}

local StorageWearable = {}

function StorageWearable.new(tool: Tool): StorageWearableObject
    local self = Wearable.new(tool)
    self.Space = tool:GetAttribute("Space")

    local associatedSlotGroup = Instance.new("ObjectValue")
    self.associatedSlotGroup = associatedSlotGroup
    associatedSlotGroup.Name = "AssociatedItemGroup"
    associatedSlotGroup.Parent = tool
    self.isUpdating = false

    StorageWearable._initialize(self)

    return self:: StorageWearableObject
end

function StorageWearable._initialize(self: StorageWearableObject)
    Wearable.initialize(
        self, 
        function() -- onWearing
            References_ItemSystem.remotes.PlaySound:FireServer(self.soundObjects.wear, self.bodyAttach, 0)
        end,
        function() -- onUnwearing
            References_ItemSystem.remotes.PlaySound:FireServer(self.soundObjects.unwear, self.bodyAttach, 0.1)
        end,
        function() -- appyWornEffects 
            LootActions.GetData(self.tool)
                :andThen(function(filledSlotsData: Types_LootSystem.StandardFilledSlotsData)
                    local slotGroup = SlotGroup.new(self.tool.Name, self.Space, filledSlotsData)
                    self.slotGroup = slotGroup
                    self.associatedSlotGroup.Value = slotGroup._itself
                end)
                :catch(function(err)
                    warn(tostring(err))
                end)
        end, 
        function() -- removeWornEffects
            if self.slotGroup then
                self.slotGroup._itself.Visible = false
                self.isUpdating = true
                LootActions.updateStorageWearableLootData(self.tool, self.slotGroup)
                    :andThen(function()
                        SlotGroup.Destroy(self.slotGroup)
                        self.associatedSlotGroup.Value = nil
                    end)
                    :catch(function(err)
                        warn(err)
                    end):finally(function()
                        self.isUpdating = false
                    end)
            end
        end
    )


end

function StorageWearable.Destroy(self: StorageWearableObject)
    Wearable.Destroy(self, function()  
        self.associatedSlotGroup:Destroy()
    end)
end

return StorageWearable