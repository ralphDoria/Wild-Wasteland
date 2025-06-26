-- Gave Claude a crazy looking nested if statement mess and asked it to rewrite it for efficiency and performance.
-- Small tweaks to make it compatible done by @Niletheus

-- idk what to call these references
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local ToolSystem_Storage = References_Inventory.ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local Types_Slot = require(InventoryScriptStorage.Components.Slot.Type_Slot)
local ToolStateMachine = require(InventoryScriptStorage.Components.ToolStateMachine.Main_ToolStateMachine)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)

-- Enum for slot types to avoid string comparisons and improve readability
type enumSlotType = {
    LOOTING_SCROLLING: number,
    LOOTING_EQUIPMENT: number,
    CHARACTER_EQUIPMENT: number,
    INVENTORY_OR_HOTBAR: number,
    INVALID: number,
}
local SlotType: enumSlotType = {
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
local function getSlotType(slot)
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
        slotGroup: Frame,
        slotType: enumSlotType
    }
local function getSlotData(slot): slotData?
    if not slot then return nil end
    
    local slotType = getSlotType(slot)

    local objValue = slot.tool and slot.tool:FindFirstChildOfClass("ObjectValue")
    local slotGroup
    if slotType == SlotType.CHARACTER_EQUIPMENT or slotType == SlotType.LOOTING_EQUIPMENT then
        slotGroup = objValue and objValue.Value
    else
        slotGroup = if slot._itself.Parent then slot._itself.Parent.Parent else nil
    end
    return {
        slotObject = slot,
        slotGroup = slotGroup,
        slotType = slotType
    }
end

-- helper function to swap two slot's positional attributes within inventory
local function simpleSlotSwap(s1Data: slotData, s2Data: slotData)
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

-- helper function to wear the current drag slot
local function localSwapAndWear(wearableSlotData: slotData, inventoryOrHotbarSlotData: slotData, changeSlotState, fillSlot, emptySlot)

    -- warn(`wearable slot group: {wearableSlotData.slotGroup}; inventory/hotbar slot group: {inventoryOrHotbarSlotData.slotGroup}`) 
    if wearableSlotData.slotGroup ~= nil and wearableSlotData.slotGroup == inventoryOrHotbarSlotData.slotGroup then return end

    local wearableSlot = wearableSlotData.slotObject
    local inventoryOrHotbarSlot = inventoryOrHotbarSlotData.slotObject

    -- print(`wearable category: {wearableSlot.WearableCategory}; inventory/hotbar tool's wearable category: {if inventoryOrHotbarSlot.tool and inventoryOrHotbarSlot.tool:GetAttribute("WearableCategory") then inventoryOrHotbarSlot.tool:GetAttribute("WearableCategory") else nil}`)
    if inventoryOrHotbarSlot.tool and wearableSlot.WearableCategory ~= inventoryOrHotbarSlot.tool:GetAttribute("WearableCategory") then return end

    local tweens: {Tween} = {}
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
        function() -- onCancelled
            
        end,
        function(status: string) --onFinished
            changeSlotState(wearableSlot, "Idle")
            changeSlotState(inventoryOrHotbarSlot, "Idle")
            if status == "Resolved" then
                if wearableSlot._isEmpty then
                    warn("Successfully wore and emptied")
                    -- successfull wore item from inventory/hotbar and now emptying its slot and filling it's new place in CharacterEquipmentSlots
                    fillSlot(wearableSlot, inventoryOrHotbarSlot.tool, "")
                    emptySlot(inventoryOrHotbarSlot)
                elseif not (wearableSlot._isEmpty and inventoryOrHotbarSlot._isEmpty) then
                    warn("Successfully swapped and wore")
                    -- took off item that was currently worn and put on item in hover slot
                    local wearableSlotTool = wearableSlot.tool
                    emptySlot(wearableSlot)
                    fillSlot(wearableSlot, inventoryOrHotbarSlot.tool, "")
                    emptySlot(inventoryOrHotbarSlot)
                    fillSlot(inventoryOrHotbarSlot, wearableSlotTool, "")
                end
            elseif status == "Cancelled" then
                for _, v in tweens do
                    if v.PlaybackState == Enum.PlaybackState.Playing then
                        v:Cancel()                        
                    end
                end
                warn("Cancelled")
            else
                warn(`Something went wrong involving {inventoryOrHotbarSlot.tool}; Promise State: {status}`)
            end
        end
    )
end

local function globalSimpleSlotSwap(inventoryOrHotbarSlotData: slotData, lootScrollingSlotData: slotData, fillSlot, emptySlot)
    LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
        LayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
        syncCheck = lootScrollingSlotData.slotObject.tool,
        newTool = inventoryOrHotbarSlotData.slotObject.tool
    }):andThen(function(lootedTool: Tool?)
        print("success")
        if lootedTool then
            -- when the server takes the newTool, the ItemMovementTracker should have automatically emptied newTool's previous slot
            fillSlot(inventoryOrHotbarSlotData.slotObject, lootedTool)
        else
            emptySlot(inventoryOrHotbarSlotData.slotObject)
        end
    end):catch(function(error)
        warn("Error", tostring(error))
    end)
end

-- helper function to take off the current drag slot
local function localUnwearAndSwapWithEmpty(wearableSlotData: slotData, inventoryOrHotbarSlotData: slotData, changeSlotState, fillSlot, emptySlot)

    -- warn(`wearable slot group: {wearableSlotData.slotGroup}; inventory/hotbar slot group: {inventoryOrHotbarSlotData.slotGroup}`)
    if wearableSlotData.slotGroup ~= nil and wearableSlotData.slotGroup == inventoryOrHotbarSlotData.slotGroup then return end

    local wearableSlot = wearableSlotData.slotObject
    local inventoryOrHotbarSlot = inventoryOrHotbarSlotData.slotObject

    local tweens: {Tween} = {}
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
            
        end,
        function(status: string) --onFinished 
            if status == "Resolved" then
                fillSlot(inventoryOrHotbarSlot, wearableSlot.tool, "")
                emptySlot(wearableSlot)
            elseif status == "Never Ran" then
                warn("Can't wear item, various possible reasons: current tool is in some activated state, item to swap with is not compatible")
            elseif status == "Cancelled" then
                for _, v in tweens do
                    if v.PlaybackState == Enum.PlaybackState.Playing then
                        v:Cancel()                        
                    end
                end
                warn("Cancelled")
            end
            if status == "Resolved" or status == "Never Ran" then
                changeSlotState(wearableSlot, "Idle")
                changeSlotState(inventoryOrHotbarSlot, "Idle")
            end
        end
    )                
end

-- Action handlers for different drag-drop combinations
local ActionHandlers = {
    -- Outside inventory actions (when isOutsideInventory is true)
    outsideInventory = {
        [SlotType.LOOTING_SCROLLING] = function(dragData)
            print("Action: Drop on crate/corpse or open drop menu")
            bindables.DropToolBindable:Fire(dragData.slotObject.tool)
        end,
        
        [SlotType.LOOTING_EQUIPMENT] = function(dragData)
            print("Action: Take off corpse and drop")
        end,
        
        [SlotType.CHARACTER_EQUIPMENT] = function(dragData)
            print("Action: Take off wearable and drop")
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
            [SlotType.LOOTING_SCROLLING] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting scrolling to looting scrolling")
            end,
            [SlotType.LOOTING_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting scrolling to looting equipment")
            end,
            [SlotType.CHARACTER_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting scrolling to character equipment")
            end,
            [SlotType.INVENTORY_OR_HOTBAR] = function(dragData: slotData, hoverData: slotData, _, fillSlot, emptySlot)
                print("Action: Looting scrolling to inventory/hotbar")
                globalSimpleSlotSwap(hoverData, dragData, fillSlot, emptySlot)
            end
        },
        
        [SlotType.LOOTING_EQUIPMENT] = {
            [SlotType.LOOTING_SCROLLING] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting equipment to looting scrolling")
            end,
            [SlotType.LOOTING_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Looting equipment to looting equipment")
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
            [SlotType.CHARACTER_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Character equipment to character equipment")
            end,
            [SlotType.INVENTORY_OR_HOTBAR] = function(dragData: slotData, hoverData: slotData, changeSlotState, fillSlot, emptySlot)
                print("Action: Character equipment to inventory/hotbar")
                if hoverData.slotObject._isEmpty then
                    localUnwearAndSwapWithEmpty(dragData, hoverData, changeSlotState, fillSlot, emptySlot)
                else
                    localSwapAndWear(hoverData, dragData, changeSlotState, fillSlot, emptySlot)
                end
            end
        },
        
        [SlotType.INVENTORY_OR_HOTBAR] = {
            [SlotType.LOOTING_SCROLLING] = function(dragData: slotData, hoverData: slotData, _, fillSlot, emptySlot)
                print("Action: Inventory/hotbar to looting scrolling")
                globalSimpleSlotSwap(dragData, hoverData, fillSlot, emptySlot)
            end,
            [SlotType.LOOTING_EQUIPMENT] = function(dragData: slotData, hoverData: slotData)
                print("Action: Inventory/hotbar to looting equipment")
            end,
            [SlotType.CHARACTER_EQUIPMENT] = function(dragData, hoverData, changeSlotState, fillSlot, emptySlot)
                print("Action: Inventory/hotbar to character equipment")
                localSwapAndWear(hoverData, dragData, changeSlotState, fillSlot, emptySlot) 
            end,
            [SlotType.INVENTORY_OR_HOTBAR] = function(dragData: slotData, hoverData: slotData)
                print("Action: Inventory/hotbar to inventory/hotbar")
                simpleSlotSwap(dragData, hoverData)
            end
        }
    }
}

-- Main function (replaces your original code block)
local function handleDragDrop(dragSlot, isOutsideInventory, hoverSlot, changeSlotState, fillSlot, emptySlot)

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
            handler(dragData)
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