local ReplicatedStorage = game:GetService("ReplicatedStorage")
local types_and_enums = require("./types_and_enums")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local ItemSystem_Storage = References_Inventory.ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local bindables = {
    DropToolBindable = ItemSystem_Storage.Shared.Bindables.DropToolBindable,
    ImmediateUnequip = ItemSystem_Storage.Shared.Bindables.ImmediateUnequip,
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local Types_Slot = require(InventoryScriptStorage.Components.Slot.Type_Slot)
local ToolStateMachine = require(InventoryScriptStorage.Components.ToolStateMachine.Main_ToolStateMachine)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)
local DiegeticErrorMessagingManager = require(ReplicatedStorage.RojoManaged_RS.DiegeticErrorMessagingManager)
local EmptySlotFinder = require(InventoryScriptStorage.Components.Slot.EmptySlotFinder)


-- helper function to swap two slot's positional attributes within inventory
local function P_INVENTORY__SWAP(s1Data: types_and_enums.SlotData, s2Data: types_and_enums.SlotData)
    local slotObject1 = s1Data.slotObject
    local slotObject2 = s2Data.slotObject

    local slotInstance1 = slotObject1._itself
    local slotInstance2 = slotObject2._itself

    if slotInstance2.Parent ~= slotInstance1.Parent then
        local s2_savedParent = slotInstance2.Parent
        slotInstance2.Parent = slotInstance1.Parent
        slotInstance1.Parent = s2_savedParent
    end

    local s2LO = slotInstance2.LayoutOrder
    local s1LO = slotInstance1.LayoutOrder
    slotInstance2.LayoutOrder = s1LO
    slotObject2.HotbarNumber.Text = tostring(s1LO)
    slotInstance1.LayoutOrder = s2LO
    slotObject1.HotbarNumber.Text = tostring(s2LO)
    if slotInstance1.Parent == References_Inventory.Hotbar then
        slotObject1.HotbarNumber.Visible = true
    else 
        slotObject1.HotbarNumber.Visible = false
    end
    if slotInstance2.Parent == References_Inventory.Hotbar then
        slotObject2.HotbarNumber.Visible = true
    else
        slotObject2.HotbarNumber.Visible = false
    end
end

-- helper function for displaying a loading effect over slot
local TweenService = References_Inventory.TweenService
local function loadSlot(slot: Types_Slot.SlotObject, duration: number)
    local progressBar = Instance.new("Frame")
    progressBar.Transparency = 0.5
    progressBar.Size = UDim2.fromScale(1, 1)
    progressBar.Parent = slot._itself
    local tween = TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)})
    tween.Completed:Connect(function()  
        progressBar:Destroy()
    end)
    return tween
end

local function isRelatedViaSlotGroup(wearableSlotData: types_and_enums.SlotData, otherSlot: types_and_enums.SlotData): boolean
    if wearableSlotData.slotGroupInstance and wearableSlotData.slotGroupInstance == otherSlot.slotGroupInstance then 
        print("checkpoint 1")
        DiegeticErrorMessagingManager.AddMessage("Logically, that's not possible")
        return true
    else
        return false    
    end
end

local function P_INVENTORY__X__L_INVENTORY(inventoryOrHotbarSlotData: types_and_enums.SlotData, lootScrollingSlotData: types_and_enums.SlotData, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot)

    local inventoryOrHotbarSlotTool: Tool? = inventoryOrHotbarSlotData.slotObject.tool
    local lootTool: Tool? = lootScrollingSlotData.slotObject.tool
    if inventoryOrHotbarSlotTool and inventoryOrHotbarSlotTool:GetAttribute("State") ~= "Unequipped" then
        warn(`immediately unequipping {inventoryOrHotbarSlotTool} because it is not unequipped`)
        bindables.ImmediateUnequip:Fire(inventoryOrHotbarSlotTool)
    end
    LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        __type = "Standard",
        lootToolLayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
        lootTool = lootTool,
        substituteTool = inventoryOrHotbarSlotTool
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
--[[
    Bug: when any wearable is held out and player tries to wear it, wearable just unequips itself
    Caused by: Main_ToolStateMachine.lua 233 caused by "and" in the if statement
    
    Attempted solution: tried to change "and" to "or", but that caused interruption handling to not work
]]
local function P_INVENTORY__X__P_EQUIPMENT(wearableSlotData: types_and_enums.SlotData, inventoryOrHotbarSlotData: types_and_enums.SlotData, changeSlotState: types_and_enums.changeSlotState, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot)
    local wearableSlot = wearableSlotData.slotObject
    local inventoryOrHotbarSlot = inventoryOrHotbarSlotData.slotObject

    --Checks

    if inventoryOrHotbarSlot.tool and inventoryOrHotbarSlot.tool:GetAttribute("WearableCategory") ~= wearableSlot.WearableCategory then
        DiegeticErrorMessagingManager.AddMessage(`{inventoryOrHotbarSlot.tool.Name} can't go into my {wearableSlot.WearableCategory} equipment slot. I'm such an idiot`)    
        return
    end
                    
    local wornItem: Tool? = wearableSlot.tool
    if wornItem and wornItem:HasTag("StorageWearable") then
        if isRelatedViaSlotGroup(wearableSlotData, inventoryOrHotbarSlotData) then return end

        if not wornItem:GetAttribute("isEmpty_client") then
            DiegeticErrorMessagingManager.AddMessage("I need to empty my backpack if I want to do that")
            return
        end
    end

    local tweens: {Tween} = {}
    if inventoryOrHotbarSlot._isEmpty then
        ToolStateMachine.SetTargets(wearableSlot, "Unequipped", 
            function(timeUntilComplete: number)
                table.insert(tweens, loadSlot(wearableSlot, timeUntilComplete))
                table.insert(tweens, loadSlot(inventoryOrHotbarSlot, timeUntilComplete))
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
        ToolStateMachine.SetTargets(inventoryOrHotbarSlot, "Worn", 
            function(estimatedPathsTime: number) -- onValidated
                changeSlotState(wearableSlot, "BeingSwapped")
                changeSlotState(inventoryOrHotbarSlot, "BeingSwapped")

                table.insert(tweens, loadSlot(wearableSlot, estimatedPathsTime))
                table.insert(tweens, loadSlot(inventoryOrHotbarSlot, estimatedPathsTime))
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
                    local emptyInventoryOrHotbarSlot = EmptySlotFinder.any()
                    if emptyInventoryOrHotbarSlot then
                        print("empty slot found")
                        local wearableTool = wearableSlot.tool
                        emptySlot(wearableSlot)
                        fillSlot(emptyInventoryOrHotbarSlot, wearableTool)
                        --TODO: DROP
                    else
                        print("emtpy slot not founding; dropping")
                        warn(wearableSlot.tool)
                        bindables.DropToolBindable:Fire(wearableSlot.tool)
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
                elseif not (wearableSlot._isEmpty and inventoryOrHotbarSlot._isEmpty) then
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

local function L_INVENTORY__SWAP(lsData0: types_and_enums.SlotData, lsData1: types_and_enums.SlotData, fillSlot, emptySlot)

    local slot0 = lsData0.slotObject
    local slot1 = lsData1.slotObject
    local slot0Tool: Tool? = slot0.tool
    local slot1Tool: Tool? = slot1.tool 
    LootActions.TrySlotInteraction(
        References_Inventory.LootableInstanceObjectValue.Value, 
        {
            __type = "Standard",
            lootToolLayoutOrder = slot0._itself.LayoutOrder,
            lootTool = slot0Tool,
            substituteTool = slot1Tool
        },
        {
            __type = "Standard",
            lootToolLayoutOrder = slot1._itself.LayoutOrder,
            lootTool = slot1Tool,
            substituteTool = slot0Tool,
        }
    )
    :andThen(function()
        print("success with lootScrolling x lootScrolling swap")
    end)
    :catch(function(error)
        warn("Error", tostring(error))
    end)
end

local function L_INVENTORY__DROP(lootScrollingSlotData: types_and_enums.SlotData)
    local lootTool: Tool? = lootScrollingSlotData.slotObject.tool
    LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        __type = "Standard",
        lootToolLayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
        lootTool = lootTool,
        substituteTool = nil
    }):andThen(function()
        task.wait() -- give time for item to instantiate
        bindables.DropToolBindable:Fire(lootTool)
    end):catch(function(error)
        warn("Error", tostring(error))
    end)
end

local function P_EQUIPMENT__DROP(characterEquipmentSlotData: types_and_enums.SlotData, changeSlotState: types_and_enums.changeSlotState, fillSlot, emptySlot)
    local characterEquipmentSlot = characterEquipmentSlotData.slotObject

    local tweens: {Tween} = {}
    ToolStateMachine.SetTargets(characterEquipmentSlot, "Idle", 
        function(estimatedPathsTime: number) -- onValidated
            changeSlotState(characterEquipmentSlot, "BeingSwapped")

            table.insert(tweens, loadSlot(characterEquipmentSlot, estimatedPathsTime))
            for _, v in tweens do
                v:Play()
            end
        end,
        function() -- onCancelled
            for _, v in tweens do
                if v.PlaybackState == Enum.PlaybackState.Playing then
                    v:Cancel()                        
                end
            end
            warn("Cancelled")
        end,
        function() --onResolved
            -- warn("resolved characterEquipment_drop")
            bindables.DropToolBindable:Fire(characterEquipmentSlot.tool)
        end,
        function(status: string)
            changeSlotState(characterEquipmentSlot, "Idle")
        end
    )
end

local function P_EQUIPMENT__X__L_INVENTORY(pEquipmentData: types_and_enums.SlotData, lInventoryData: types_and_enums.SlotData, changeSlotState: types_and_enums.changeSlotState, fillSlot: types_and_enums.fillSlot, emptySlot: types_and_enums.emptySlot, newSlot: types_and_enums.newSlot, destroySlot: types_and_enums.destroySlot)
    --[[
        - Going to be modeled off of inventoryOrHotbar_x_characterEquipment_swap
            - which is split into 3 scenarios: 

                1. EMPTY lootScrolling slot and FILLED characterEquipment slot - unwear characterEquipment and fill lootScrolling slot
                    - if lootScrolling slot is filled during the asynchronous process of unwearing, then the wearable will find another slot to fill within
                        loot scrolling frame. If there are no empty slots to fill, then the equipment item will be dropped
                2. FILLED lootScrolling slot and EMPTY characterEquipment slot - empty lootScrolling slot and start wearing item
                    - (abstract this into ToolStateMachine)if wearing is cancelled, then item is put into inventory, and classic procedure, 
                        if there's no space in inventory, then item will be dropped
                3. FILLED lootScrolling slot and FILLED characterEquipment slot - the gist of it is that the player wants to wear the lootScrolling item and get rid of
                    their current worn item by putting it into the lootContainer, so no matter the edge case, I should try to honor that desire
                    - lootScrolling item will be put into the inventory and put into the unequippe state (so that it can be handled by ToolStateMachine), but won't
                        be given a slot at this point.
                        - classic case of tool statemachine swap two wearable items: 
                            - implement at ToolStateMachine level so that it can deal with cancellations consistently across all 3 lootScrolling_x_characterEquipment_swap cases
    ]]
    local lInventorySlot = lInventoryData.slotObject
    local pEquipmentSlot = pEquipmentData.slotObject
    local pIsEmpty = pEquipmentData.slotObject._isEmpty
    local lIsEmpty = lInventoryData.slotObject._isEmpty

    if not pIsEmpty and pEquipmentSlot.tool:GetAttribute("isEmpty_client") == false then
        DiegeticErrorMessagingManager.AddMessage("I need to empty my backpack if I want to do that")
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
        LootActions.TrySlotInteraction(originalLootableInstance, {
            __type = "Standard",
            lootToolLayoutOrder = originalLootLayoutOrder,
            lootTool = lootTool,
            substituteTool = nil     
        })
        :andThen(function()
            -- start unwearing process
            local temporarySlotObject = newSlot("Inventory") 
            fillSlot(temporarySlotObject, lootTool)
            local tweens: {Tween} = {}
            ToolStateMachine.SetTargets(temporarySlotObject, "Worn", 
                function(timeUntilComplete: number)
                    table.insert(tweens, loadSlot(pEquipmentSlot, timeUntilComplete))
                    table.insert(tweens, loadSlot(lInventorySlot, timeUntilComplete))
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
                    local emptyInventoryOrHotbarSlot = EmptySlotFinder.any()
                    if emptyInventoryOrHotbarSlot then
                        fillSlot(emptyInventoryOrHotbarSlot, lootTool)
                    else
                        bindables.DropToolBindable:Fire(lootTool)
                    end
                end,
                function() --onResolved 
                    fillSlot(pEquipmentSlot, lootTool)
                end,
                function() --onFinished
                    destroySlot(temporarySlotObject)
                    changeSlotState(lInventorySlot, "Idle")
                    changeSlotState(pEquipmentSlot, "Idle")
                end,
                function() --onNonTargetUnworn  
                    -- TODO put original tool in pEquipmentData in lootTool's previous position
                    if originalLootableInstance == References_Inventory.LootableInstanceObjectValue.Value then
                        LootActions.TrySlotInteraction(originalLootableInstance, {
                            __type = "Standard",
                            lootToolLayoutOrder = originalLootLayoutOrder,
                            lootTool = nil,
                            substituteTool = pEquipmentTool  
                        })
                        :catch(function(err)
                            warn("Dropping tool because try slot interaction for pEquipmentTool failed")
                            warn(tostring(err))
                            bindables.DropToolBindable:Fire(pEquipmentTool)
                        end)
                    else
                        warn("Dropping tool because  original lootable instance is not longer the current lootable instance")
                        bindables.DropToolBindable:Fire(pEquipmentTool)
                    end
                end
            )   
        end)
    elseif not pIsEmpty then
        -- start unwearing operation. If gui is closed during this, then item will be dropped. Otherwise, item will be put in the indicated loot inventory slot.
        local tweens: {Tween} = {}
        ToolStateMachine.SetTargets(pEquipmentSlot, "Idle", 
            function(timeUntilComplete: number)
                table.insert(tweens, loadSlot(lInventoryData.slotObject, timeUntilComplete))
                table.insert(tweens, loadSlot(pEquipmentSlot, timeUntilComplete))
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
                    bindables.DropToolBindable:Fire(pEquipmentTool)
                else
                    LootActions.TrySlotInteraction(lootableInstance, {
                        __type = "Standard",
                        lootToolLayoutOrder = lInventoryData.slotObject._itself.LayoutOrder,
                        lootTool = nil,
                        substituteTool = pEquipmentSlot.tool
                    })
                    :andThen(function()
                        bindables.ImmediateUnequip:Fire(pEquipmentTool)
                        emptySlot(pEquipmentSlot)
                        fillSlot(lInventoryData.slotObject, pEquipmentTool)
                    end)
                    :catch(function(err)
                        warn(tostring(err))
                        bindables.DropToolBindable:Fire(pEquipmentTool)
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
        LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
            __type = "Standard",
            lootToolLayoutOrder = lInventoryData.slotObject._itself.LayoutOrder,
            lootTool = lootTool,
            substituteTool = nil     
        })
        :andThen(function()
            -- start wearing process
            local temporarySlotObject = newSlot("Inventory") 
            fillSlot(temporarySlotObject, lootTool)
            local tweens: {Tween} = {}
            ToolStateMachine.SetTargets(temporarySlotObject, "Worn", 
                function(timeUntilComplete: number)
                    table.insert(tweens, loadSlot(temporarySlotObject, timeUntilComplete))
                    table.insert(tweens, loadSlot(pEquipmentSlot, timeUntilComplete))
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
                    local emptyInventoryOrHotbarSlot = EmptySlotFinder.any()
                    if emptyInventoryOrHotbarSlot then
                        fillSlot(emptyInventoryOrHotbarSlot, lootTool)
                    else
                        bindables.DropToolBindable:Fire(lootTool)
                    end
                end,
                function() --onResolved 
                    local wearableTool = temporarySlotObject.tool
                    fillSlot(pEquipmentSlot, wearableTool)
                end,
                function() --onFinished
                    destroySlot(temporarySlotObject)
                    changeSlotState(pEquipmentSlot, "Idle")
                end
            )   
        end)
        :catch(function(errorMsg)
            warn(`Failed slot interaction to remove looting tool from server registry: ` .. tostring(errorMsg))
        end)
    end
end

local P_INVENTORY = types_and_enums.EnumSlotType.P_INVENTORY
local P_EQUIPMENT = types_and_enums.EnumSlotType.P_EQUIPMENT
local L_INVENTORY = types_and_enums.EnumSlotType.L_INVENTORY
local L_EQUIPMENT = types_and_enums.EnumSlotType.L_EQUIPMENT

local ActionHandlers: types_and_enums.ActionHandlers = {
    -- Outside inventory actions (when isOutsideInventory is true)
    outsideInventory = {
        [L_INVENTORY] = function(dragData)
            print("Action: Drop on crate/corpse or open drop menu")
            L_INVENTORY__DROP(dragData)
        end,
        
        [L_EQUIPMENT] = function(dragData)
            print("Action: Take off corpse and drop")
        end,
        
        [P_EQUIPMENT] = function(dragData, _, changeSlotState, fillSlot, emptySlot)
            print("Action: Take off wearable and drop")
            P_EQUIPMENT__DROP(dragData, changeSlotState, fillSlot, emptySlot)
        end,
        
        [P_INVENTORY] = function(dragData)
            print("Action: Use ItemSystem drop method or open drop menu")
            bindables.DropToolBindable:Fire(dragData.slotObject.tool)
        end
    },
    
    -- Inside inventory actions (slot-to-slot transfers)
    insideInventory = {
        -- [dragType][hoverType] = handler
        [L_INVENTORY] = {
            [L_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, _, fillSlot, emptySlot)
                print("Action: Looting scrolling to looting scrolling")
                L_INVENTORY__SWAP(dragData, hoverData, fillSlot, emptySlot)
            end,
            [L_EQUIPMENT] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Looting scrolling to looting equipment")
            end,
            [P_EQUIPMENT] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
                print("Action: Looting scrolling to character equipment")
                P_EQUIPMENT__X__L_INVENTORY(hoverData, dragData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
            end,
            [P_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, _, fillSlot, emptySlot)
                print("Action: Looting scrolling to inventory/hotbar")
                P_INVENTORY__X__L_INVENTORY(hoverData, dragData, fillSlot, emptySlot)
            end
        },
        
        [L_EQUIPMENT] = {
            [L_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Looting equipment to looting scrolling")
            end,
            [P_EQUIPMENT] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Looting equipment to character equipment")
            end,
            [P_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Looting equipment to inventory/hotbar")
            end
        },
        
        [P_EQUIPMENT] = {
            [L_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
                print("Action: Character equipment to looting scrolling")
                P_EQUIPMENT__X__L_INVENTORY(dragData, hoverData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
            end,
            [L_EQUIPMENT] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Character equipment to looting equipment")
            end,
            [P_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, changeSlotState, fillSlot, emptySlot)
                print("Action: Character equipment to inventory/hotbar")
                P_INVENTORY__X__P_EQUIPMENT(dragData, hoverData, changeSlotState, fillSlot, emptySlot)
            end
        },
        
        [P_INVENTORY] = {
            [L_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, _, fillSlot, emptySlot)
                print("Action: Inventory/hotbar to looting scrolling")
                P_INVENTORY__X__L_INVENTORY(dragData, hoverData, fillSlot, emptySlot)
            end,
            [L_EQUIPMENT] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Inventory/hotbar to looting equipment")
            end,
            [P_EQUIPMENT] = function(dragData, hoverData, changeSlotState, fillSlot, emptySlot)
                print("Action: Inventory/hotbar to character equipment")
                P_INVENTORY__X__P_EQUIPMENT(hoverData, dragData, changeSlotState, fillSlot, emptySlot)
            end,
            [P_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Inventory/hotbar to inventory/hotbar")
                P_INVENTORY__SWAP(dragData, hoverData)
            end
        }
    }
}

return ActionHandlers