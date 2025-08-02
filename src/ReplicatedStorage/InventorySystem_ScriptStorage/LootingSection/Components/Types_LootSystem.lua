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

--[[
    Narrows FilledSlotsData type with property checks
]]
function Types_LootSystem.isCorpseFilledSlotsDataType(filledSlotsData: any)
    return filledSlotsData["1"] and not (filledSlotsData["1"].ClassName == "Tool")
end

Types_LootSystem.EnumEquipmentSlots = {
    ["Carry Belt"] = 0, -- Represents the items in the player's hotbar
    ["Head"] = 1,
    ["Torso"] = 2,
    ["Backpack"] = 3,
    ["Legs"] = 4,
    ["Feet"] = 5
}

local function findValueInDictionary(dictionary: {any: any}, value: any)
    for _, v in dictionary do
        if v == value then
            return v
        end
    end
    return nil
end

--[[
    Gets the equipment slot name based on the equipment slot number
]]
Types_LootSystem.getEquipmentSlotName = function(equipmentSlotNumber: number): string?
    assert(type(equipmentSlotNumber) == "number", "This function uses equipmentSlotNumber, so type of parameter needs to be a number")
    return findValueInDictionary(Types_LootSystem.EnumEquipmentSlots, equipmentSlotNumber)
end

type LootableObject = {
    _itself: Model | Tool,
    Space: number,
    _numberOfItems: number,
    DataChangeReplicatorRemote: RemoteEvent
}

export type StandardLootableObject = LootableObject & {
    FilledSlotsData: StandardFilledSlotsData,
}

export type CorpseLootableObject = LootableObject & {
    FilledSlotsData: CorpseFilledSlotsData,
}

export type DataChangeRequest<T> = {
    __type: T, 
    lootToolLayoutOrder: number,
    lootTool: Tool?,
    substituteTool: Tool?
}

export type StandardDataChangeRequest = DataChangeRequest<"Standard">

-- If the lootToolLayourOrder and lootTool properties are nil, then that means equipmentTool is to be replaced with the substitute tool.
export type CorpseDataChangeRequest =  DataChangeRequest<"Corpse"> & {equipmentToolLayoutOrder: number, equipmentTool: Tool}

export type callbacks = {
    takeLoot: (Player) -> (),
    doSubstitution: () -> ()
}

return Types_LootSystem