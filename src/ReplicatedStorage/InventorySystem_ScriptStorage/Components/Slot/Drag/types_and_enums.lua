local types_and_enums = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage

-- Enum for slot types to avoid string comparisons and improve readability
types_and_enums.EnumSlotType = {
    L_INVENTORY = 1,
    L_EQUIPMENT = 2,
    P_EQUIPMENT = 3,
    P_INVENTORY = 4,
    INVALID = 5
}

local Types_Slot = require(InventoryScriptStorage.Components.Slot.Type_Slot)
local Type_Equipment = require(InventoryScriptStorage.CharacterSection.Components.Type_Equipment)

export type changeSlotState= (Types_Slot.SlotObject, Types_Slot.SlotState) -> ()
export type fillSlot= (Types_Slot.SlotObject, Tool?) -> ()
export type emptySlot= (Types_Slot.SlotObject) -> ()
export type newSlot = (slotType : "Hotbar" | "Inventory" | "Wearable", wearableCategory: Type_Equipment.EquipmentCategory?) -> Types_Slot.SlotObject
export type destroySlot = (Types_Slot.SlotObject) -> ()

export type SlotObject = Types_Slot.SlotObject

export type SlotData = {
    slotObject: Types_Slot.SlotObject,
    slotGroupInstance: Frame?,
    slotType: number
}

export type actionHandler= (dragData: SlotData, hoverData: SlotData, changeSlotState: changeSlotState, fillSlot: fillSlot, emptySlot: emptySlot, newSlot: newSlot, destroySlot: destroySlot) -> ()

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

return types_and_enums