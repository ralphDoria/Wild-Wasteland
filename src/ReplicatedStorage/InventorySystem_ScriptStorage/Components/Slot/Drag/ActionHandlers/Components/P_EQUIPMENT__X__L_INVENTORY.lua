local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local Types_LootSystem = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local Utility = require(script.Parent.Parent.Utility)

--for testing, DELETE later
local ScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local SlotRegistry = require(ScriptStorage.Components.Slot.SlotRegistry)

local function P_EQUIPMENT__X__L_INVENTORY(pEquipmentData: types_and_enums.SlotData, lInventoryData: types_and_enums.SlotData, changeSlotState: types_and_enums.changeSlotState, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot, newSlot: types_and_enums.newSlot, destroySlot: types_and_enums.destroySlot)
    --[[
        - Going to be modeled off of inventoryOrHotbar_x_characterEquipment_swap
            - which is split into 3 scenarios: 

                1. EMPTY lootScrolling slot and FILLED characterEquipment slot - unwear characterEquipment and fill lootScrolling slot
                    - if lootScrolling slot is filled during the asynchronous process of unwearing, then the wearable will find another slot to fill within
                        loot scrolling frame. If there are no empty slots to fill, then the equipment item will be dropped
                2. FILLED lootScrolling slot and EMPTY characterEquipment slot - empty lootScrolling slot and start wearing item
                    - (abstract this into References_ActionHandlers.ToolStateMachine)if wearing is cancelled, then item is put into inventory, and classic procedure, 
                        if there's no space in inventory, then item will be dropped
                3. FILLED lootScrolling slot and FILLED characterEquipment slot - the gist of it is that the player wants to wear the lootScrolling item and get rid of
                    their current worn item by putting it into the lootContainer, so no matter the edge case, I should try to honor that desire
                    - lootScrolling item will be put into the inventory and put into the unequippe state (so that it can be handled by References_ActionHandlers.ToolStateMachine), but won't
                        be given a slot at this point.
                        - classic case of tool statemachine swap two wearable items: 
                            - implement at References_ActionHandlers.ToolStateMachine level so that it can deal with cancellations consistently across all 3 lootScrolling_x_characterEquipment_swap cases
    ]]
    local lInventorySlot = lInventoryData.slotObject
    local pEquipmentSlot = pEquipmentData.slotObject
    local pIsEmpty = pEquipmentData.slotObject._isEmpty
    local lIsEmpty = lInventoryData.slotObject._isEmpty

    local equipmentToolLayoutOrder, equipmentTool = Utility.getLootInventorySlotEquipmentToolInfo(lInventorySlot)
    local requestType = if equipmentToolLayoutOrder then Types_LootSystem.EnumLootableTypes.Corpse else Types_LootSystem.EnumLootableTypes.Standard
    warn(Types_LootSystem.EnumLootableTypes.Corpse, Types_LootSystem.EnumLootableTypes.Standard, `requesttype: {requestType}`)

    if not pIsEmpty and pEquipmentSlot.tool:GetAttribute("isEmpty_client") == false then
        References_ActionHandlers.DiegeticErrorMessagingManager.AddMessage("I need to empty my backpack if I want to do that")
        return
    end
    
    if not pIsEmpty and not lIsEmpty then
       --[[
            Just like picking up a filled backpack from the ground, the wearable will be taken from the server registry and implicitly stored in the player's inventory while the wearing process for the current wearable
            is started. If interrupted, the implicitly stored item will find a place in the inventory so it can be explicitly stored. If inventory is full, then item will be dropped.
       ]] 
        local lootTool = lInventorySlot.tool
        local pEquipmentTool = pEquipmentSlot.tool
        local originalLootableInstance = References_Inventory.LootableInstanceObjectValue.Value
        local originalLootLayoutOrder = lInventorySlot._itself.LayoutOrder  
        References_ActionHandlers.LootActions.TrySlotInteraction(originalLootableInstance, {
            __type = requestType,
            lootToolLayoutOrder = originalLootLayoutOrder,
            lootTool = lootTool,
            substituteTool = nil,
            equipmentToolLayoutOrder = equipmentToolLayoutOrder,
            equipmentTool = equipmentTool
        })
        :andThen(function()
            -- start unwearing process
            local temporarySlotObject = newSlot("Inventory") 
            fillSlot(temporarySlotObject, lootTool)
            local tweens: {Tween} = {}
            task.wait() -- wait for loot tool to instantiate when it enters player's inventory
            References_ActionHandlers.ToolStateMachine.SetTargets(temporarySlotObject, "Worn", 
                function(timeUntilComplete: number)
                    table.insert(tweens, Utility.loadSlot(pEquipmentSlot, timeUntilComplete))
                    table.insert(tweens, Utility.loadSlot(lInventorySlot, timeUntilComplete))
                    for _, v in tweens do
                        v:Play()
                    end

                    changeSlotState(temporarySlotObject, "BeingSwapped")
                    changeSlotState(pEquipmentSlot, "BeingSwapped")
                    changeSlotState(lInventorySlot, "BeingSwapped")
                end,
                function() --onCancelled
                    for _, v in tweens do
                        if v.PlaybackState == Enum.PlaybackState.Playing then
                            v:Cancel()                        
                        end
                    end
                    -- warn("Cancelled")
                    local emptyInventoryOrHotbarSlot = References_ActionHandlers.EmptySlotFinder.any()
                    if emptyInventoryOrHotbarSlot then
                        destroySlot(temporarySlotObject)
                        fillSlot(emptyInventoryOrHotbarSlot, lootTool)
                    else
                        destroySlot(temporarySlotObject)
                        References_ActionHandlers.bindables.DropToolBindable:Fire(lootTool)
                    end
                end,
                function() --onResolved 
                    destroySlot(temporarySlotObject)
                    fillSlot(pEquipmentSlot, lootTool)
                end,
                function() --onFinished
                    changeSlotState(lInventorySlot, "Idle")
                    changeSlotState(pEquipmentSlot, "Idle")
                end,
                function() --onNonTargetUnworn  
                    -- TODO put original tool in pEquipmentData in lootTool's previous position
                    if originalLootableInstance == References_Inventory.LootableInstanceObjectValue.Value then
                        References_ActionHandlers.LootActions.TrySlotInteraction(originalLootableInstance, {
                            __type = requestType,
                            lootToolLayoutOrder = originalLootLayoutOrder,
                            lootTool = nil,
                            substituteTool = pEquipmentTool,
                            equipmentToolLayoutOrder = equipmentToolLayoutOrder,
                            equipmentTool = equipmentTool

                        })
                        :catch(function(err)
                            warn("Dropping tool because try slot interaction for pEquipmentTool failed")
                            warn(tostring(err))
                            References_ActionHandlers.bindables.DropToolBindable:Fire(pEquipmentTool)
                        end)
                    else
                        warn("Dropping tool because  original lootable instance is not longer the current lootable instance")
                        References_ActionHandlers.bindables.DropToolBindable:Fire(pEquipmentTool)
                    end
                end
            )   
        end)
    elseif not pIsEmpty then
        -- start unwearing operation. If gui is closed during this, then item will be dropped. Otherwise, item will be put in the indicated loot inventory slot.
        local tweens: {Tween} = {}
        References_ActionHandlers.ToolStateMachine.SetTargets(pEquipmentSlot, "Idle", 
            function(timeUntilComplete: number)
                table.insert(tweens, Utility.loadSlot(lInventoryData.slotObject, timeUntilComplete))
                table.insert(tweens, Utility.loadSlot(pEquipmentSlot, timeUntilComplete))
                for _, v in tweens do
                    v:Play()
                end

                changeSlotState(lInventoryData.slotObject, "BeingSwapped")
                changeSlotState(pEquipmentSlot, "BeingSwapped")
            end,
            function() --onCancelled
                for _, v in tweens do
                    if v.PlaybackState == Enum.PlaybackState.Playing then
                        v:Cancel()                        
                    end
                end
            end,
            function() --onResolved 
                local pEquipmentTool = pEquipmentSlot.tool
                local lootableInstance = References_Inventory.LootableInstanceObjectValue.Value 
                if lootableInstance == nil then
                    References_ActionHandlers.bindables.DropToolBindable:Fire(pEquipmentTool)
                else
                    References_ActionHandlers.LootActions.TrySlotInteraction(lootableInstance, {
                        __type = requestType,
                        lootToolLayoutOrder = if lInventoryData.slotObject._itself then lInventoryData.slotObject._itself.LayoutOrder else nil,
                        lootTool = nil,
                        substituteTool = pEquipmentSlot.tool,
                        equipmentToolLayoutOrder = equipmentToolLayoutOrder,
                        equipmentTool = equipmentTool
                    })
                    :andThen(function()
                        print("filling inventory slot")
                        References_ActionHandlers.bindables.ImmediateUnequip:Fire(pEquipmentTool)
                        emptySlot(pEquipmentSlot)
                        fillSlot(lInventoryData.slotObject, pEquipmentTool) 
                    end)
                    :catch(function(err)
                        print("error, dropping item")
                        warn(tostring(err))
                        References_ActionHandlers.bindables.DropToolBindable:Fire(pEquipmentTool)
                    end)
                end
            end,
            function() --onFinished
                changeSlotState(pEquipmentSlot, "Idle")
                changeSlotState(lInventoryData.slotObject, "Idle")
            end
        )   
    elseif not lIsEmpty then
        -- item will be removed from server registry and the wearing process will start for it locally. If cancelled, the item will find a place in the inventory. If full, then it will be dropped.
        local lootTool = lInventoryData.slotObject.tool
        References_ActionHandlers.LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
            __type = requestType,
            lootToolLayoutOrder = lInventoryData.slotObject._itself.LayoutOrder,
            lootTool = lootTool,
            substituteTool = nil,
            equipmentToolLayoutOrder = equipmentToolLayoutOrder,
            equipmentTool = equipmentTool
        })
        :andThen(function()
            -- start wearing process
            local temporarySlotObject = newSlot("Inventory") 
            fillSlot(temporarySlotObject, lootTool)
            local tweens: {Tween} = {}
            task.wait() -- wait for item to initilize in their inventory
            References_ActionHandlers.ToolStateMachine.SetTargets(temporarySlotObject, "Worn", 
                function(timeUntilComplete: number)
                    table.insert(tweens, Utility.loadSlot(temporarySlotObject, timeUntilComplete))
                    table.insert(tweens, Utility.loadSlot(pEquipmentSlot, timeUntilComplete))
                    for _, v in tweens do
                        v:Play()
                    end

                    changeSlotState(temporarySlotObject, "BeingSwapped")
                    changeSlotState(pEquipmentSlot, "BeingSwapped")
                end,
                function() --onCancelled
                    for _, v in tweens do
                        if v.PlaybackState == Enum.PlaybackState.Playing then
                            v:Cancel()                        
                        end
                    end
                    -- warn("Cancelled")
                    local emptyInventoryOrHotbarSlot = References_ActionHandlers.EmptySlotFinder.any()
                    if emptyInventoryOrHotbarSlot then
                        destroySlot(temporarySlotObject)
                        fillSlot(emptyInventoryOrHotbarSlot, lootTool)
                    else
                        destroySlot(temporarySlotObject)
                        References_ActionHandlers.bindables.DropToolBindable:Fire(lootTool)
                    end
                end,
                function() --onResolved 
                    local wearableTool = temporarySlotObject.tool
                    destroySlot(temporarySlotObject)
                    fillSlot(pEquipmentSlot, wearableTool)
                end,
                function() --onFinished
                    changeSlotState(pEquipmentSlot, "Idle")
                end
            )   
        end)
        :catch(function(errorMsg)
            warn(`Failed slot interaction to remove looting tool from server registry: ` .. tostring(errorMsg))
        end)
    end
end

return P_EQUIPMENT__X__L_INVENTORY
