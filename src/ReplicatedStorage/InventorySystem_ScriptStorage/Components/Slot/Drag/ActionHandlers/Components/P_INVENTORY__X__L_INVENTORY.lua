local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local Utility = require(script.Parent.Parent.Utility)

local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)

local function P_INVENTORY__X__L_INVENTORY(inventoryOrHotbarSlotData: types_and_enums.SlotData, lootScrollingSlotData: types_and_enums.SlotData, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot)

    local inventoryOrHotbarSlotTool: Tool? = inventoryOrHotbarSlotData.slotObject.tool
    local lootTool: Tool? = lootScrollingSlotData.slotObject.tool
    if inventoryOrHotbarSlotTool and inventoryOrHotbarSlotTool:GetAttribute("State") ~= "Unequipped" then
        warn(`immediately unequipping {inventoryOrHotbarSlotTool} because it is not unequipped`)
        References_ActionHandlers.bindables.ImmediateUnequip:Fire(inventoryOrHotbarSlotTool)
    end

    local equipmentToolLayoutOrder, equipmentTool = Utility.getLootInventorySlotEquipmentToolInfo(lootScrollingSlotData.slotObject)

    References_ActionHandlers.LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        __type = if equipmentToolLayoutOrder then Types_LootSystem.EnumLootableTypes.Corpse else Types_LootSystem.EnumLootableTypes.Standard,
        lootToolLayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
        lootTool = lootTool,
        substituteTool = inventoryOrHotbarSlotTool,
        equipmentToolLayoutOrder = equipmentToolLayoutOrder,
        equipmentTool = equipmentTool
    }):andThen(function()
        local inventoryTool = inventoryOrHotbarSlotData.slotObject.tool
        if lootTool and not inventoryTool then
            -- when the server takes the substituteTool, the ItemMovementTracker should have automatically emptied substituteTool's previous slot
            emptySlot(lootScrollingSlotData.slotObject)
            fillSlot(inventoryOrHotbarSlotData.slotObject, lootTool)
        elseif inventoryTool and not lootTool then
            emptySlot(inventoryOrHotbarSlotData.slotObject)
            fillSlot(lootScrollingSlotData.slotObject, inventoryTool)
        else
            emptySlot(inventoryOrHotbarSlotData.slotObject)
            emptySlot(lootScrollingSlotData.slotObject)
            fillSlot(inventoryOrHotbarSlotData.slotObject, lootTool)
            fillSlot(lootScrollingSlotData.slotObject, inventoryTool)
        end
    end):catch(function(error)
        warn("Error", tostring(error))
    end)
end

return P_INVENTORY__X__L_INVENTORY