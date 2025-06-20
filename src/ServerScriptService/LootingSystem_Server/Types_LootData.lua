local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local Type_Equipment = require(InventoryScriptStorage.CharacterSection.Components.Type_Equipment)

export type SingleLootItem = {
    [Tool]: {
        Grabbed: boolean,
        LayoutOrder: number,
    }
}

export type StorageEquipment = {
    [Tool]: {
        Grabbed: boolean,
        EquipmentCategory: Type_Equipment.EquipmentCategory,
        SlotGroup: {
            SingleLootItem
        }
    }
}

export type Corpse = {
    [Instance]: {
        StorageEquipment
    } 
}

export type Regular = {
    [Instance]: {
        [Tool]: {
            Grabbed: boolean,
            LayoutOrder: number
        }
    }
}

export type LootCategory = "Regular" | "Corpse" | "StorageEquipment"



return nil