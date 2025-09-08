local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local Types_LootSystem = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local Utility = require(script.Parent.Parent.Utility)

local ItemSystem_Storage = ReplicatedStorage.ItemSystem_Storage
local remotes = {
    RequestMergeStackables = ItemSystem_Storage.Stackable.Remotes.RequestMergeStackables:: RemoteFunction,
}

local function L_INVENTORY__SWAP(lsData0: types_and_enums.SlotData, lsData1: types_and_enums.SlotData, fillSlot, emptySlot)

    -- If stackables of same type, then merge
    local sourceTool = lsData0.slotObject.tool
    local destinationTool = lsData1.slotObject.tool
    if sourceTool and destinationTool then
        if sourceTool.Name == destinationTool.Name then
            if sourceTool:GetAttribute("Quantity") then
                task.spawn(function()
                    remotes.RequestMergeStackables:InvokeServer(sourceTool, destinationTool)
                end)
                return
            end
        end
    end

    local slot0 = lsData0.slotObject
    local slot1 = lsData1.slotObject
    local slot0Tool: Tool? = slot0.tool
    local slot1Tool: Tool? = slot1.tool 

    -- if we happen to be dealing with a CorpseLootable

    local equipmentLayoutOrder0
    local equipmentLayoutOrder1
    local equipmentTool0
    local equipmentTool1
    
    local requestType

    if #References_Inventory.LootingEquipmentSlots:GetChildren() > 1 then
        equipmentLayoutOrder0, equipmentTool0 = Utility.getLootInventorySlotEquipmentToolInfo(slot0)
        equipmentLayoutOrder1, equipmentTool1 = Utility.getLootInventorySlotEquipmentToolInfo(slot1)

        requestType = Types_LootSystem.EnumLootableTypes.Corpse
    else
        requestType = Types_LootSystem.EnumLootableTypes.Standard
    end
    -- local slot1EquipmentLayoutOrder = 

    References_ActionHandlers.LootActions.TrySlotInteraction(
        References_Inventory.LootableInstanceObjectValue.Value, 
        {
            __type = requestType,
            lootToolLayoutOrder = slot0._itself.LayoutOrder,
            lootTool = slot0Tool,
            substituteTool = slot1Tool,
            equipmentToolLayoutOrder = equipmentLayoutOrder0, -- may be nil if dealing with StandardLootable
            equipmentTool = equipmentTool0, -- may be nil if dealing with StandardLootable
        },
        {
            __type = requestType,
            lootToolLayoutOrder = slot1._itself.LayoutOrder,
            lootTool = slot1Tool,
            substituteTool = slot0Tool,
            equipmentToolLayoutOrder = equipmentLayoutOrder1, -- may be nil if dealing with StandardLootable
            equipmentTool = equipmentTool1, -- may be nil if dealing with StandardLootable
        }
    )
    :andThen(function()
        print("success with lootScrolling x lootScrolling swap")
    end)
    :catch(function(error)
        warn("Error", tostring(error))
    end)
end

return L_INVENTORY__SWAP
