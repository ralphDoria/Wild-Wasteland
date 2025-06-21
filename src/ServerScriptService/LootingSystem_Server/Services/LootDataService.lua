local Types_LootData = require(game:GetService("ServerScriptService").RojoManaged_SSS.LootingSystem_Server.Types_LootData)
local Type_Equipment = require(InventoryScriptStorage.CharacterSection.Components.Type_Equipment)

local LootDataService = {}

local RegularLoot: Types_LootData.Regular = {}

local CorpseLoot: Types_LootData.Corpse = {}

type entry = {
    category: Types_LootData.LootCategory,
    DataStructure: {Types_LootData.Regular | Types_LootData.StorageEquipment | Types_LootData.Corpse}
}

function LootDataService.Register(category: Types_LootData.LootCategory, lootable: Instance)    
    if category == "Regular" then
        if RegularLoot[lootable] == nil then
            RegularLoot[lootable] = {}
        end
    elseif category == "Corpse" then
        if CorpseLoot[lootable] == nil then
            CorpseLoot[lootable] = {}        
        end
    else
        warn(`Unrecognized category type {category}`)
    end
end

type ItemData_Regular = {
    tool: Tool,
    LayoutOrder: number
}

function LootDataService.AddItemToRegular(lootable, , ...: ItemData_Regular)
    assert(RegularLoot[lootable] ~= nil, `{lootable} is not registered as a regular lootable.`)

    local args = {...}
    for _, v: ItemData_Regular in args do
        RegularLoot[lootable][v.tool] = {
            v.Grabbed = false,
            v.LayoutOrder = v.LayoutOrder
        }
    end
end

type ItemData_Corpse = {
    tool: Tool,
    EquipmentCategory: 
    location: {
        SlotGroup: Tool?,
        LayoutOrder: number
    }
}

function LootDataService.WearOnCorpse(lootable, , ...: ItemData_Corpse)
    assert(CorpseLoot[lootable] ~= nil, `{lootable} is not registered as a corpse lootable.`)

    local args = {...}
    for _, v: ItemData_Regular in args do
        RegularLoot[lootable][v.tool] = {
            Grabbed = v.Grabbed,
            EquipmentCategory = v.
            Slotgroup = {}            
        }
    end
end

function LootDataService.GetData(lootable: Instance): Types_LootData.Regular | Types_LootData.StorageEquipment | Types_LootData.Corpse
    return MasterList[lootable]
end

return LootDataService