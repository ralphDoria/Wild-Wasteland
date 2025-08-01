local Types_LootSystem = {}

-- This is here to prevent bugs due to typos in other files
Types_LootSystem.EnumLootableTypes = {
    ["Standard"] = "Standard",
    ["Corpse"] = "Corpse"
}

export type StandardFilledSlotsData = {
    [string]: Tool? -- string will be a number in the form of a string which'll represent the Layout Order
}

export type CorpseFilledSlotsData = {
    [string]: {
        equipmentTool: Tool?,
        slotGroupData: StandardFilledSlotsData
    } 
}

Types_LootSystem.EnumEquipmentSlots = {
    ["Head"] = 1,
    ["Torso"] = 2,
    ["Backpack"] = 3,
    ["Legs"] = 4,
    ["Feet"] = 5
}

export type StandardLootableObject = {
    _itself: Model | Tool,
    Space: number,
    _numberOfItems: number,
    FilledSlotsData: StandardFilledSlotsData,
    DataChangeReplicatorRemote: RemoteEvent
}

export type CorpseLootableObject = {
    _itself: Model,
    Space: number, --very fluid and can change depending on what equipment the corpse has on
    _numberOfItems: number,
    FilledSlotsData: CorpseFilledSlotsData,
    DataChangeReplicatorRemote: RemoteEvent
}

type DataChangeRequestPacket<T> = {
    __type: T, 
    lootToolLayoutOrder: number,
    lootTool: Tool?,
    substituteTool: Tool?
}

export type StandardDataChangeRequestPacket = DataChangeRequestPacket<"Standard">

-- If the lootToolLayourOrder and lootTool properties are nil, then that means equipmentTool is to be replaced with the substitute tool.
export type CorpseDataChangeRequestPacket =  DataChangeRequestPacket<"Corpse"> & {equipmentToolLayoutOrder: number, equipmentTool: Tool}

return Types_LootSystem