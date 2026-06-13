local ReplicatedStorage = game:GetService("ReplicatedStorage")
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local Utility = require(script.Parent.Parent.Utility)

local function P_INVENTORY__X__P_EQUIPMENT(wearableSlotData: types_and_enums.SlotData, inventoryOrHotbarSlotData: types_and_enums.SlotData, changeSlotState: types_and_enums.changeSlotState, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot)
    local wearableSlot = wearableSlotData.slotObject
    local inventoryOrHotbarSlot = inventoryOrHotbarSlotData.slotObject

    --Checks

    if inventoryOrHotbarSlot.tool and inventoryOrHotbarSlot.tool:GetAttribute("WearableCategory") ~= wearableSlot.WearableCategory then
        References_ActionHandlers.DiegeticErrorMessagingManager.AddMessage(`{inventoryOrHotbarSlot.tool.Name} can't go into my {wearableSlot.WearableCategory} equipment slot. I'm such an idiot`)    
        return
    end
                    
    local wornItem: Tool? = wearableSlot.tool
    if wornItem and wornItem:HasTag("StorageWearable") then
        if Utility.isRelatedViaSlotGroup(wearableSlotData, inventoryOrHotbarSlotData) then return end

        if not wornItem:GetAttribute("isEmpty_client") then
            References_ActionHandlers.DiegeticErrorMessagingManager.AddMessage("I need to empty my backpack if I want to do that")
            return
        end
    end

    local tweens: {Tween} = {}
    if inventoryOrHotbarSlot._isEmpty then
        References_ActionHandlers.ToolStateMachine.SetTargets(wearableSlot, "Unequipped", 
            function(timeUntilComplete: number)
                table.insert(tweens, Utility.loadSlot(wearableSlot, timeUntilComplete))
                table.insert(tweens, Utility.loadSlot(inventoryOrHotbarSlot, timeUntilComplete))
                for _, v in tweens do
                    v:Play()
                end

                changeSlotState(wearableSlot, "BeingSwapped")
                changeSlotState(inventoryOrHotbarSlot, "BeingSwapped")
            end,
            function() --onCancelled
                for _, v in tweens do
                    if v.PlaybackState == Enum.PlaybackState.Playing then
                        v:Cancel()                        
                    end
                end
                -- warn("Cancelled")
            end,
            function() --onResolved 
                local wearableTool = wearableSlot.tool
                emptySlot(wearableSlot)
                fillSlot(inventoryOrHotbarSlot, wearableTool)
            end,
            function() --onFinished
                changeSlotState(wearableSlot, "Idle")
                changeSlotState(inventoryOrHotbarSlot, "Idle")
            end
        )   
    else
        References_ActionHandlers.ToolStateMachine.SetTargets(inventoryOrHotbarSlot, "Worn", 
            function(estimatedPathsTime: number) -- onValidated
                changeSlotState(wearableSlot, "BeingSwapped")
                changeSlotState(inventoryOrHotbarSlot, "BeingSwapped")

                table.insert(tweens, Utility.loadSlot(wearableSlot, estimatedPathsTime))
                table.insert(tweens, Utility.loadSlot(inventoryOrHotbarSlot, estimatedPathsTime))
                for _, v in tweens do
                    v:Play()
                end
            end,
            function(completedUnwearing: boolean?) -- onCancelled
                for _, v in tweens do
                    if v.PlaybackState == Enum.PlaybackState.Playing then
                        v:Cancel()                        
                    end
                end
                if completedUnwearing then
                    local emptyPlayerInventorySlot = References_ActionHandlers.EmptySlotFinder.any()
                    if emptyPlayerInventorySlot then
                        print("empty slot found")
                        local wearableTool = wearableSlot.tool
                        emptySlot(wearableSlot)
                        fillSlot(emptyPlayerInventorySlot, wearableTool)
                        --TODO: DROP
                    else
                        print("emtpy slot not founding; dropping")
                        warn(wearableSlot.tool)
                        References_ActionHandlers.bindables.DropToolBindable:Fire(wearableSlot.tool)
                    end
                    --TODO
                end
                -- warn("Cancelled")
            end,
            function() --onResolved
                if wearableSlot._isEmpty then
                    -- warn("Successfully wore and emptied")
                    -- successfull wore item from inventory/hotbar and now emptying its slot and filling it's new place in CharacterEquipmentSlots
                    assert(inventoryOrHotbarSlot.tool)
                    local tool = inventoryOrHotbarSlot.tool
                    emptySlot(inventoryOrHotbarSlot)
                    fillSlot(wearableSlot, tool)
                else
                    warn("Successfully swapped and wore")
                    -- took off item that was currently worn and put on item in hover slot
                    local wearableSlotTool = wearableSlot.tool
                    emptySlot(wearableSlot)
                    assert(inventoryOrHotbarSlot.tool and wearableSlotTool)
                    fillSlot(wearableSlot, inventoryOrHotbarSlot.tool)
                    emptySlot(inventoryOrHotbarSlot)
                    fillSlot(inventoryOrHotbarSlot, wearableSlotTool)
                end
            end,
            function(status: string)
                changeSlotState(wearableSlot, "Idle")
                changeSlotState(inventoryOrHotbarSlot, "Idle")
            end
        )
    end
end

return P_INVENTORY__X__P_EQUIPMENT