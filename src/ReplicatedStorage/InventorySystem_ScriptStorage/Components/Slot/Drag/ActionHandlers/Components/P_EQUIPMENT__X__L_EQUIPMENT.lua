local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local Types_LootSystem = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local Utility = require(script.Parent.Parent.Utility)

--[[
    Heavily modeled off of P_EQUIPMENT__X__L_INVENTORY because their scenarios are nearly the same.
]]
local function P_EQUIPMENT__X__L_EQUIPMENT(pEquipmentData: types_and_enums.SlotData, lEquipmentData: types_and_enums.SlotData, changeSlotState: types_and_enums.changeSlotState, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot, newSlot: types_and_enums.newSlot, destroySlot: types_and_enums.destroySlot)
    local lEquipmentSlot = lEquipmentData.slotObject
    local pEquipmentSlot = pEquipmentData.slotObject

    if lEquipmentSlot.WearableCategory ~= pEquipmentSlot.WearableCategory then
        References_ActionHandlers.DiegeticErrorMessagingManager.AddMessage(`Wearable categories are incompatible`)    
        return
    end
                    
    local pIsEmpty = pEquipmentData.slotObject._isEmpty
    local lIsEmpty = lEquipmentData.slotObject._isEmpty

    local equipmentToolLayoutOrder, equipmentTool = Utility.getLootInventorySlotEquipmentToolInfo(lEquipmentSlot)
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
        local lootTool = lEquipmentSlot.tool
        local pEquipmentTool = pEquipmentSlot.tool
        local originalLootableInstance = References_Inventory.LootableInstanceObjectValue.Value
        local originalLootLayoutOrder = lEquipmentSlot._itself.LayoutOrder  
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
                    table.insert(tweens, Utility.loadSlot(lEquipmentSlot, timeUntilComplete))
                    for _, v in tweens do
                        v:Play()
                    end

                    changeSlotState(temporarySlotObject, "BeingSwapped")
                    changeSlotState(pEquipmentSlot, "BeingSwapped")
                    changeSlotState(lEquipmentSlot, "BeingSwapped")
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
                    changeSlotState(lEquipmentSlot, "Idle")
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
                table.insert(tweens, Utility.loadSlot(lEquipmentData.slotObject, timeUntilComplete))
                table.insert(tweens, Utility.loadSlot(pEquipmentSlot, timeUntilComplete))
                for _, v in tweens do
                    v:Play()
                end

                changeSlotState(lEquipmentData.slotObject, "BeingSwapped")
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
                        lootToolLayoutOrder = if lEquipmentData.slotObject._itself then lEquipmentData.slotObject._itself.LayoutOrder else nil,
                        lootTool = nil,
                        substituteTool = pEquipmentSlot.tool,
                        equipmentToolLayoutOrder = equipmentToolLayoutOrder,
                        equipmentTool = equipmentTool
                    })
                    :andThen(function()
                        print("filling inventory slot")
                        References_ActionHandlers.bindables.ImmediateUnequip:Fire(pEquipmentTool)
                        emptySlot(pEquipmentSlot)
                        fillSlot(lEquipmentData.slotObject, pEquipmentTool) 
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
                changeSlotState(lEquipmentData.slotObject, "Idle")
            end
        )   
    elseif not lIsEmpty then
        -- item will be removed from server registry and the wearing process will start for it locally. If cancelled, the item will find a place in the inventory. If full, then it will be dropped.
        local lootTool = lEquipmentData.slotObject.tool
        References_ActionHandlers.LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
            __type = requestType,
            lootToolLayoutOrder = lEquipmentData.slotObject._itself.LayoutOrder,
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

return P_EQUIPMENT__X__L_EQUIPMENT