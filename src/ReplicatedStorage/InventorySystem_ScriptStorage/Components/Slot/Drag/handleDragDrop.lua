--!strict

-- Gave Claude a crazy looking nested if statement mess and asked it to rewrite it for efficiency and performance.
-- Small tweaks to make it compatible done by @Niletheus

-- idk what to call these references
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local types_and_enums = require("./types_and_enums")
local ActionHandlers = require("./ActionHandlers/ActionHandlers")

-- Cache references to avoid repeated property access
local LootingScrollingName = References_Inventory.LootingScrollingFrame.Name
local LootingEquipmentName = References_Inventory.LootingEquipmentSlots.Name
local CharacterEquipmentName = References_Inventory.CharacterEquipmentSlots.Name
local InventoryScrollingName = References_Inventory.InventoryScrollingFrame.Name
local HotbarName = References_Inventory.Hotbar.Name


-- Helper function to determine slot type (cached for performance)
local function getSlotType(slot): number
    local element = slot._itself
    
    if element:FindFirstAncestor(LootingScrollingName) then
        return types_and_enums.EnumSlotType.L_INVENTORY
    elseif element:FindFirstAncestor(LootingEquipmentName) then
        return types_and_enums.EnumSlotType.L_EQUIPMENT
    elseif element:FindFirstAncestor(CharacterEquipmentName) then
        return types_and_enums.EnumSlotType.P_EQUIPMENT
    elseif element:FindFirstAncestor(InventoryScrollingName) or element:FindFirstAncestor(HotbarName) then
        return types_and_enums.EnumSlotType.P_INVENTORY
    else
        return types_and_enums.EnumSlotType.INVALID
    end
end

local function getSlotData(slotObject: types_and_enums.SlotObject): types_and_enums.SlotData
    local slotType = getSlotType(slotObject)

    local slotGroupInstance: Frame?
    if slotType == types_and_enums.EnumSlotType.P_EQUIPMENT or slotType == types_and_enums.EnumSlotType.L_EQUIPMENT then
    local objValue: ObjectValue? = if slotObject.tool then slotObject.tool:FindFirstChildOfClass("ObjectValue") else nil
        slotGroupInstance = if objValue and objValue.Value then objValue.Value:: Frame else nil
    else
        slotGroupInstance = if slotObject._itself.Parent then slotObject._itself.Parent.Parent:: Frame else nil
    end

    return {
        slotObject = slotObject,
        slotGroupInstance = slotGroupInstance,
        slotType = slotType
    }
end


-- Main function (replaces your original code block)
local function handleDragDrop(dragSlot, isOutsideInventory: boolean, hoverSlot: types_and_enums.SlotObject?, changeSlotState: types_and_enums.changeSlotState, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot, newSlot: types_and_enums.newSlot, destroySlot: types_and_enums.destroySlot)

    if dragSlot == hoverSlot then return end

    -- Get drag slot data
    local dragData = getSlotData(dragSlot)
    if dragData.slotType == types_and_enums.EnumSlotType.INVALID then
        warn("Invalid drag slot ancestry")
        return
    end
    
    if isOutsideInventory then
        -- Handle outside inventory drops
        local handler = ActionHandlers.outsideInventory[dragData.slotType]
        if handler then
            handler(dragData, hoverSlot:: any, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
        else
            warn("No handler for outside inventory drop from slot type: " .. dragData.slotType)
        end
    else
        -- Handle inside inventory transfers
        if not hoverSlot or dragSlot == hoverSlot then
            warn("Not a valid swap scenario: hovering in inventory but not on a slot, or hovering on drag slot.")
            return
        end
        
        local hoverData = getSlotData(hoverSlot)
        if hoverData.slotType == types_and_enums.EnumSlotType.INVALID then
            warn("Invalid hover slot ancestry")
            return
        end
        
        local dragHandlers = ActionHandlers.insideInventory[dragData.slotType]
        if dragHandlers then
            local handler = dragHandlers[hoverData.slotType]
            if handler then
                handler(dragData, hoverData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
            else
                warn("No handler for drag type " .. dragData.slotType .. " to hover type " .. hoverData.slotType)
            end
        else
            warn("No handlers for drag slot type: " .. dragData.slotType)
        end
    end
end

return handleDragDrop