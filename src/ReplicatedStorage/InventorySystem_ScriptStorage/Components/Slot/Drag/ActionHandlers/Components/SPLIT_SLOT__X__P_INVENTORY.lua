local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)


local DiegeticErrorMessaging = require(ReplicatedStorage.RojoManaged_RS.DiegeticErrorMessagingManager)

local EmptySlotFinder = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.EmptySlotFinder)
local StackableSlotFinder = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.StackableSlotFinder)

local ItemSystem_Storage = ReplicatedStorage.ItemSystem_Storage
local remotes = {
    RequestMergeStackables = ItemSystem_Storage.Stackable.Remotes.RequestMergeStackables:: RemoteFunction,
}

local function SPLIT_SLOT__X__P_INVENTORY(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, fillSlot)
    -- dragData will always be the split slot
    local splitSlot = dragData.slotObject
    local pInventorySlot = hoverData.slotObject

    local pInventoryTool = pInventorySlot.tool
    if pInventoryTool then
        if pInventoryTool.Name == splitSlot.tool.Name then -- if they are the same stackable
            -- fire remote event to request merge 

            local sourceTool = splitSlot.tool:: Tool
            if pInventoryTool:GetAttribute("Quantity") < pInventoryTool:GetAttribute("MAX_QUANTITY") then
                -- signal to SpittingMenu to toggle loading icon
                dragData.slotObject._itself:SetAttribute("Merging", true) 
                remotes.RequestMergeStackables:InvokeServer(sourceTool, pInventoryTool) -- this yields until serverside operation completes
                local slotInstance = dragData.slotObject._itself
                if not slotInstance then return end -- this means that player exited SplittingMenu (via clicking outside of gui), however values should still be set properly on server
                if sourceTool.Parent == nil then
                    slotInstance:SetAttribute("Used", true) 
                else
                    -- signal to SplittingMenu to update maxQuantity
                    slotInstance:SetAttribute("UpdateSplittingMenuMaxQuantity", true) 
                end
                task.wait()
                slotInstance:SetAttribute("Merging", nil) 
            end
        else
            print("Can't merge, not same stackable type")
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