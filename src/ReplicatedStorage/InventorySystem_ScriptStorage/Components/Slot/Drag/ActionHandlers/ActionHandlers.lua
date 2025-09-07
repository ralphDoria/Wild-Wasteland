local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ActionHandlers = require(script.Parent.References_ActionHandlers)

-- Type modules (moved here because they can't be used properly through references)
local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local types_and_enums = require(InventoryScriptStorage.Components.Slot.Drag.types_and_enums)

local P_INVENTORY__SWAP = require("./Components/P_INVENTORY__SWAP")
local P_INVENTORY__X__L_INVENTORY = require("./Components/P_INVENTORY__X__L_INVENTORY")
local P_INVENTORY__X__P_EQUIPMENT = require("./Components/P_INVENTORY__X__P_EQUIPMENT")
local L_INVENTORY__SWAP = require("./Components/L_INVENTORY__SWAP")
local L_INVENTORY__DROP = require("./Components/L_INVENTORY__DROP")
local L_EQUIPMENT__DROP = require("./Components/L_EQUIPMENT__DROP")
local P_EQUIPMENT__DROP = require("./Components/P_EQUIPMENT__DROP")
local P_EQUIPMENT__X__L_INVENTORY = require("./Components/P_EQUIPMENT__X__L_INVENTORY")
local P_EQUIPMENT__X__L_EQUIPMENT = require("./Components/P_EQUIPMENT__X__L_EQUIPMENT")
local L_EQUIPMENT__X_P_INVENTORY = require("./Components/L_EQUIPMENT__X__P_INVENTORY")
local SPLIT_SLOT__X__L_INVENTORY = require("./Components/SPLIT_SLOT__X__L_INVENTORY")
local SPLIT_SLOT__X__P_INVENTORY = require("./Components/SPLIT_SLOT__X__P_INVENTORY")


-- Enum slot types
local P_INVENTORY = types_and_enums.EnumSlotType.P_INVENTORY
local P_EQUIPMENT = types_and_enums.EnumSlotType.P_EQUIPMENT
local L_INVENTORY = types_and_enums.EnumSlotType.L_INVENTORY
local L_EQUIPMENT = types_and_enums.EnumSlotType.L_EQUIPMENT
local SPLIT_SLOT = types_and_enums.EnumSlotType.SPLIT_SLOT

local ActionHandlers: types_and_enums.ActionHandlers = {
    -- Outside inventory actions (when isOutsideInventory is true)
    outsideInventory = {
        [L_INVENTORY] = function(dragData)
            print("Action: Drop on crate/corpse or open drop menu")
            L_INVENTORY__DROP(dragData)
        end,
        
        [L_EQUIPMENT] = function(dragData)
            print("Action: Take off corpse and drop")
            L_EQUIPMENT__DROP(dragData)
        end,
        
        [P_EQUIPMENT] = function(dragData, _, changeSlotState, fillSlot, emptySlot)
            print("Action: Take off wearable and drop")
            P_EQUIPMENT__DROP(dragData, changeSlotState, fillSlot, emptySlot)
        end,
        
        [P_INVENTORY] = function(dragData)
            print("Action: Use ItemSystem drop method or open drop menu")
            References_ActionHandlers.bindables.DropToolBindable:Fire(dragData.slotObject.tool)
        end,
        [SPLIT_SLOT] = function(dragData)
            print("Action: Drop split slot")
            -- SPLIT_SLOT__DROP()
            local stackableTool = dragData.slotObject.tool:: Tool
            
            References_ActionHandlers.bindables.DropToolBindable:Fire(stackableTool)
            dragData.slotObject._itself:SetAttribute("Used", true)
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
            end,
        },
        
        [L_EQUIPMENT] = {
            [L_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData)
                print("Action: Looting equipment to looting scrolling")
            end,
            [P_EQUIPMENT] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
                print("Action: Looting equipment to character equipment")
                P_EQUIPMENT__X__L_EQUIPMENT(hoverData, dragData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
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
            [L_EQUIPMENT] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
                print("Action: Character equipment to looting equipment")
                P_EQUIPMENT__X__L_EQUIPMENT(dragData, hoverData, changeSlotState, fillSlot, emptySlot, newSlot, destroySlot)
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
            end,
        },
        [SPLIT_SLOT] = {
            [P_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, _, fillSlot)
                print("Action: split slot to player inventory slot")
                SPLIT_SLOT__X__P_INVENTORY(dragData, hoverData, fillSlot)
            end,
            [L_INVENTORY] = function(dragData: types_and_enums.SlotData, hoverData: types_and_enums.SlotData, _, fillSlot, emptySlot)
                print("Action: split slot to loot inventory slot")
                SPLIT_SLOT__X__L_INVENTORY(dragData, hoverData, fillSlot, emptySlot)
            end,
        }
    }
}

return ActionHandlers