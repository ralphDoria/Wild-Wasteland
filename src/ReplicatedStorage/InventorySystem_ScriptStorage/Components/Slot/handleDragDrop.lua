--!strict

-- Gave Claude a crazy looking nested if statement mess and asked it to rewrite it for efficiency and performance.
-- Small tweaks to make it compatible done by @Niletheus

-- idk what to call these references
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local ToolSystem_Storage = References_Inventory.ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
    ImmediateUnequip = ToolSystem_Storage.Shared.Bindables.ImmediateUnequip,
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local Types_Slot = require(InventoryScriptStorage.Components.Slot.Type_Slot)
local ToolStateMachine = require(InventoryScriptStorage.Components.ToolStateMachine.Main_ToolStateMachine)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)
local DiegeticErrorMessagingManager = require(ReplicatedStorage.RojoManaged_RS.DiegeticErrorMessagingManager)
local EmptySlotFinder = require(InventoryScriptStorage.Components.Slot.EmptySlotFinder)

-- Enum for slot types to avoid string comparisons and improve readability
local SlotType = {
    LOOTING_SCROLLING = 1,
    LOOTING_EQUIPMENT = 2,
    CHARACTER_EQUIPMENT = 3,
    INVENTORY_OR_HOTBAR = 4,
    INVALID = 5
}


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
        return SlotType.LOOTING_SCROLLING
    elseif element:FindFirstAncestor(LootingEquipmentName) then
        return SlotType.LOOTING_EQUIPMENT
    elseif element:FindFirstAncestor(CharacterEquipmentName) then
        return SlotType.CHARACTER_EQUIPMENT
    elseif element:FindFirstAncestor(InventoryScrollingName) or element:FindFirstAncestor(HotbarName) then
        return SlotType.INVENTORY_OR_HOTBAR
    else
        return SlotType.INVALID
    end
end

-- Helper function to get slot data
export type slotData = {
    slotObject: Types_Slot.SlotObject,
    slotGroupInstance: Frame?,
    slotType: number
}
local function getSlotData(slotObject: Types_Slot.SlotObject): slotData
    local slotType = getSlotType(slotObject)

    local slotGroupInstance: Frame?
    if slotType == SlotType.CHARACTER_EQUIPMENT or slotType == SlotType.LOOTING_EQUIPMENT then
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

-- helper function to swap two slot's positional attributes within inventory
local function inventoryOrHotbar_swap(s1Data: slotData, s2Data: slotData)
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

local function isRelatedViaSlotGroup(wearableSlotData: slotData, otherSlot: slotData): boolean
    if wearableSlotData.slotGroupInstance and wearableSlotData.slotGroupInstance == otherSlot.slotGroupInstance then 
        print("checkpoint 1")
        DiegeticErrorMessagingManager.AddMessage("Logically, that's not possible")
        return true
    else
        return false    
    end
end

local function inventoryOrHotbar_x_lootScrolling_swap(inventoryOrHotbarSlotData: slotData, lootScrollingSlotData: slotData, fillSlot: fillSlot, emptySlot: emptySlot)

    local inventoryOrHotbarSlotTool: Tool? = inventoryOrHotbarSlotData.slotObject.tool
    local lootTool: Tool? = lootScrollingSlotData.slotObject.tool
    if inventoryOrHotbarSlotTool and inventoryOrHotbarSlotTool:GetAttribute("State") ~= "Unequipped" then
        warn(`immediately unequipping {inventoryOrHotbarSlotTool} because it is not unequipped`)
        bindables.ImmediateUnequip:Fire(inventoryOrHotbarSlotTool)
    end
    LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        LayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
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

local function characterEquipment_x_inventoryOrHotbar_swap(wearableSlotData: slotData, inventoryOrHotbarSlotData: slotData, changeSlotState: changeSlotState, fillSlot: fillSlot, emptySlot: emptySlot)
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

local function lootScrolling_x_lootScrolling_swap(lsData0: slotData, lsData1: slotData, fillSlot, emptySlot)

    local slot0 = lsData0.slotObject
    local slot1 = lsData1.slotObject
    local slot0Tool: Tool? = slot0.tool
    local slot1Tool: Tool? = slot1.tool 
    LootActions.TrySlotInteraction(
        References_Inventory.LootableInstanceObjectValue.Value, 
        {
            LayoutOrder = slot0._itself.LayoutOrder,
            lootTool = slot0Tool,
            substituteTool = slot1Tool
        },
        {
            LayoutOrder = slot1._itself.LayoutOrder,
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

local function lootScrolling_drop(lootScrollingSlotData: slotData)
    local lootTool: Tool? = lootScrollingSlotData.slotObject.tool
    LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        LayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
        lootTool = lootTool,
        substituteTool = nil
    }):andThen(function()
        bindables.DropToolBindable:Fire(lootTool)
    end):catch(function(error)
        warn("Error", tostring(error))
    end)
end

local function characterEquipment_drop(characterEquipmentSlotData: slotData, changeSlotState: changeSlotState, fillSlot, emptySlot)
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

local function lootScrolling_x_characterEquipment_swap(lootScrollingData: slotData, characterEquipmentData: slotData)
    --[[
        - Going to be modeled off of inventoryOrHotbar_x_characterEquipment_swap
            - which is split into 3 scenarios: 

                * need to fix edge case handling for when a state path execution is cancelled and the wearable is unworn first because the cases below rely on it.

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
end

-- Action handlers for different drag-drop combinations

type changeSlotState = (Types_Slot.SlotObject, Types_Slot.SlotState) -> ()
type fillSlot = (Types_Slot.SlotObject, Tool?) -> ()
type emptySlot = (Types_Slot.SlotObject) -> ()

type actionHandler = (dragData: slotData, hoverData: slotData, changeSlotState: changeSlotState, fillSlot: fillSlot, emptySlot: emptySlot) -> ()

export type ActionHandlers = {
    outsideInventory: {
        [number]: actionHandler
    },
    insideInventory: {
        [number]: {
            [number]: actionHandler
        }
    }
}

local ActionHandlers: ActionHandlers = {
    -- Outside inventory actions (when isOutsideInventory is true)
    outsideInventory = {
        [SlotType.LOOTING_SCROLLING] = function(dragData)
            print("Action: Drop on crate/corpse or open drop menu")
            lootScrolling_drop(dragData)
        end,
        
        [SlotType.LOOTING_EQUIPMENT] = function(dragData)
            print("Action: Take off corpse and drop")
        end,
        
        [SlotType.CHARACTER_EQUIPMENT] = function(dragData, _, changeSlotState, fillSlot, emptySlot)
            print("Action: Take off wearable and drop")
            characterEquipment_drop(dragData, changeSlotState, fillSlot, emptySlot)
        end,
        
        [SlotType.INVENTORY_OR_HOTBAR] = function(dragData)
            print("Action: Use ItemSystem drop method or open drop menu")
            bindables.DropToolBindable:Fire(dragData.slotObject.tool)
        end
    },
    
    -- Inside inventory actions (slot-to-slot transfers)
    insideInventory = {
        -- [dragType][hoverType] = handler
        [SlotType.LOOTING_SCROLLING] = {
            [SlotType.LOOTING_SCROLLING] = function(dragData: slotData, hoverData: slotData, _, fillSlot, emptySlot)
                print("Action: Looting scrolling to looting scrolling")
                lootScrolling_x_lootScrolling_swap(dragData, hoverData, fillSlot, emptySlot)
            end,
            [SlotType.LOOTING_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting scrolling to looting equipment")
            end,
            [SlotType.CHARACTER_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting scrolling to character equipment")
            end,
            [SlotType.INVENTORY_OR_HOTBAR] = function(dragData: slotData, hoverData: slotData, _, fillSlot, emptySlot)
                print("Action: Looting scrolling to inventory/hotbar")
                inventoryOrHotbar_x_lootScrolling_swap(hoverData, dragData, fillSlot, emptySlot)
            end
        },
        
        [SlotType.LOOTING_EQUIPMENT] = {
            [SlotType.LOOTING_SCROLLING] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting equipment to looting scrolling")
            end,
            [SlotType.CHARACTER_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting equipment to character equipment")
            end,
            [SlotType.INVENTORY_OR_HOTBAR] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting equipment to inventory/hotbar")
            end
        },
        
        [SlotType.CHARACTER_EQUIPMENT] = {
            [SlotType.LOOTING_SCROLLING] = function(dragData: slotData, hoverData: slotData)
                print("Action: Character equipment to looting scrolling")
            end,
            [SlotType.LOOTING_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Character equipment to looting equipment")
            end,
            [SlotType.INVENTORY_OR_HOTBAR] = function(dragData: slotData, hoverData: slotData, changeSlotState, fillSlot, emptySlot)
                print("Action: Character equipment to inventory/hotbar")
                characterEquipment_x_inventoryOrHotbar_swap(dragData, hoverData, changeSlotState, fillSlot, emptySlot)
            end
        },
        
        [SlotType.INVENTORY_OR_HOTBAR] = {
            [SlotType.LOOTING_SCROLLING] = function(dragData: slotData, hoverData: slotData, _, fillSlot, emptySlot)
                print("Action: Inventory/hotbar to looting scrolling")
                inventoryOrHotbar_x_lootScrolling_swap(dragData, hoverData, fillSlot, emptySlot)
            end,
            [SlotType.LOOTING_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Inventory/hotbar to looting equipment")
            end,
            [SlotType.CHARACTER_EQUIPMENT] = function(dragData, hoverData, changeSlotState, fillSlot, emptySlot)
                print("Action: Inventory/hotbar to character equipment")
                characterEquipment_x_inventoryOrHotbar_swap(hoverData, dragData, changeSlotState, fillSlot, emptySlot)
            end,
            [SlotType.INVENTORY_OR_HOTBAR] = function(dragData: slotData, hoverData: slotData)
                print("Action: Inventory/hotbar to inventory/hotbar")
                inventoryOrHotbar_swap(dragData, hoverData)
            end
        }
    }
}

-- Main function (replaces your original code block)
local function handleDragDrop(dragSlot, isOutsideInventory: boolean, hoverSlot: Types_Slot.SlotObject?, changeSlotState: changeSlotState, fillSlot: fillSlot, emptySlot: emptySlot)

    if dragSlot == hoverSlot then return end

    -- Get drag slot data
    local dragData = getSlotData(dragSlot)
    if dragData.slotType == SlotType.INVALID then
        warn("Invalid drag slot ancestry")
        return
    end
    
    if isOutsideInventory then
        -- Handle outside inventory drops
        local handler = ActionHandlers.outsideInventory[dragData.slotType]
        if handler then
            handler(dragData, hoverSlot:: any, changeSlotState, fillSlot, emptySlot)
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
        if hoverData.slotType == SlotType.INVALID then
            warn("Invalid hover slot ancestry")
            return
        end
        
        local dragHandlers = ActionHandlers.insideInventory[dragData.slotType]
        if dragHandlers then
            local handler = dragHandlers[hoverData.slotType]
            if handler then
                handler(dragData, hoverData, changeSlotState, fillSlot, emptySlot)
            else
                warn("No handler for drag type " .. dragData.slotType .. " to hover type " .. hoverData.slotType)
            end
        else
            warn("No handlers for drag slot type: " .. dragData.slotType)
        end
    end
end

return handleDragDrop