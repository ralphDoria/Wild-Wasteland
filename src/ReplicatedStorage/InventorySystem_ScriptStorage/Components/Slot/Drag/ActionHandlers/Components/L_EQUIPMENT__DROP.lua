local ReplicatedStorage = game:GetService("ReplicatedStorage")

local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local References_Inventory = require(InventoryScriptStorage.Components.References_Inventory_Client)
local types_and_enums = require(InventoryScriptStorage.Components.Slot.Drag.types_and_enums)

local ToolCatalog: Folder = ReplicatedStorage:FindFirstChild("ToolCatalog", true)

local LootingSystem_Storage = ReplicatedStorage.LootingSystem_Storage
local remotes = {
    ToggleWornWearableAccessory = LootingSystem_Storage.Remotes.ToggleWornWearableAccessory:: RemoteEvent,
}

local Utility = require(script.Parent.Parent.Utility)

--[[
    If it is a non StorageWearable:
    - use TrySlotInterction to remove equipment tool from LootDataService
    - use LootGuiManager.replaceSlot to empty slot on all clients
    - remember to use task.wait() to wait for item to instantiate in player's inventory, then fire the drop tool bindable

    If it is a StorageWearable:
    - If empty then:
        - use this; create a new LootGuiManager function for emptying equipment slots & deleting their associated slot groups
    - if filled then:
        -

    
]]
local function L_EQUIPMENT__DROP(lootEquipmentSlotData: types_and_enums.SlotData)
    local lootEquipmentSlot = lootEquipmentSlotData.slotObject
    local lootEquipmentTool = lootEquipmentSlot.tool
    References_ActionHandlers.LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        __type = "Corpse",
        lootToolLayoutOrder = nil,
        lootTool = nil,
        substituteTool = nil,
        equipmentToolLayoutOrder = lootEquipmentSlot._itself.LayoutOrder, -- may be nil if dealing with StandardLootable
        equipmentTool = lootEquipmentTool, -- may be nil if dealing with StandardLootable
    }):andThen(function()
        task.wait() -- give time for item to instantiate because when a tool is dropped, it actually passed through the player's backpack first

        References_ActionHandlers.bindables.DropToolBindable:Fire(lootEquipmentTool)

        local corpseCharacterValue: ObjectValue? = lootEquipmentTool:FindFirstChild("CorpseCharacterValue")
        local corpseCharacter = if corpseCharacterValue then corpseCharacterValue.Value else nil

        local toolFolder = ToolCatalog:FindFirstChild(lootEquipmentTool.Name, true)
        local originalAccessory = toolFolder:FindFirstChildWhichIsA("Accessory", true):: Accessory

        remotes.ToggleWornWearableAccessory:FireServer(false, corpseCharacter, originalAccessory)
    end):catch(function(error)
        warn("Error", tostring(error))
    end)
end

return L_EQUIPMENT__DROP
