local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)

local function SPLIT_SLOT__X__P_INVENTORY(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, fillSlot)
    -- dragData will always be the split slot
    local splitSlot = dragData.slotObject
    local pInventorySlot = hoverData.slotObject

    local pInventoryTool = pInventorySlot.tool
    if pInventoryTool then
        if pInventoryTool.Name == splitSlot.tool.Name then -- if they are the same stackable
            -- fire remote event to request merge 
        end
    else
        -- pInventorySlot is empty, so fill the slot
        local splitSlotTool = splitSlot.tool
        --[[
            the line below signals to the SplittingMenuManager to clean up SplitSlotMenu for this stackable, including destroying the slot, so we have to do that before filling the slot to prevent 
            clobbering the SlotRegistry.toolToObjectMap.
        ]] 
        dragData.slotObject._itself:SetAttribute("Used", true) 
        task.wait()-- realize I have to defer this so that the TaskScheduler knows to switch over to SplittingMenuManager to receive the fired signal and do its cleanup
        fillSlot(pInventorySlot, splitSlotTool)
    end

end

return SPLIT_SLOT__X__P_INVENTORY