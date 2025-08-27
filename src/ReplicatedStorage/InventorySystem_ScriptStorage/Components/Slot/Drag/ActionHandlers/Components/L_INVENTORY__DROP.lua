local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local Types_LootSystem = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local Utility = require(script.Parent.Parent.Utility)

local function L_INVENTORY__DROP(lootScrollingSlotData: types_and_enums.SlotData)
    local lootTool: Tool? = lootScrollingSlotData.slotObject.tool
    local equipmentLayoutOrder, equipmentTool = Utility.getLootInventorySlotEquipmentToolInfo(lootScrollingSlotData.slotObject)
    References_ActionHandlers.LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        __type = if equipmentLayoutOrder then Types_LootSystem.EnumLootableTypes.Corpse else Types_LootSystem.EnumLootableTypes.Standard,
        lootToolLayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
        lootTool = lootTool,
        substituteTool = nil,
        equipmentToolLayoutOrder = equipmentLayoutOrder,
        equipmentTool = equipmentTool
    }):andThen(function()
        task.wait() -- give time for item to instantiate
        References_ActionHandlers.bindables.DropToolBindable:Fire(lootTool)
    end):catch(function(error)
        warn("Error", tostring(error))
    end)
end

return L_INVENTORY__DROP
