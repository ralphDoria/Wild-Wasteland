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

local function isUnmaxedStackable(slot: types_and_enums.SlotObject)
    assert(slot.tool)
    local currentQuantity = slot.tool:GetAttribute("Quantity")
    local MAX_QUANTITY = slot.tool:GetAttribute("MAX_QUANTITY")
    if currentQuantity and MAX_QUANTITY and currentQuantity ~= MAX_QUANTITY then
        return true
    else
        return false
    end
end

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
                remotes.RequestMergeStackables:InvokeServer(sourceTool, pInventoryTool) -- this yields until serverside operation completes
            end

            local foundUnmaxedStackable: boolean = true
            while foundUnmaxedStackable and sourceTool.Parent ~= nil do -- remember that stackables are destroyed when their quantity reaches 0
                local unmaxedStackable = StackableSlotFinder.any(splitSlot.tool.Name)
                if unmaxedStackable == nil then
                    foundUnmaxedStackable = false
                    continue -- continues to empty slot finder
                else
                    local destinationTool = unmaxedStackable.tool
                    remotes.RequestMergeStackables:InvokeServer(sourceTool, destinationTool) -- this yields until serverside operation completes
                end
            end

            local emptySlot = EmptySlotFinder.any()
            if emptySlot then
                -- split slot stackable is already in inventory, so just fill a slot
                local splitSlotTool = splitSlot.tool
                dragData.slotObject._itself:SetAttribute("Used", true) 
                task.wait()-- realize I have to defer this so that the TaskScheduler knows to switch over to SplittingMenuManager to receive the fired signal and do its cleanup
                fillSlot(emptySlot, splitSlotTool)
            else
                DiegeticErrorMessaging.AddMessage("I can't carry any more items")
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