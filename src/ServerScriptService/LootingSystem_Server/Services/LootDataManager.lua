local Types_LootData = require(game:GetService("ServerScriptService").RojoManaged_SSS.LootingSystem_Server.Types_LootData)

local LootDataManager = {}

type entry = {
    category: Types_LootData.LootCategory,
    DataStructure: {Types_LootData.Regular | Types_LootData.StorageEquipment | Types_LootData.Corpse}
}

local MasterList: {entry} = {}

local function entryExists(lootable: Instance)
    return MasterList[lootable] ~= nil
end

function LootDataManager.Register(category: Types_LootData.LootCategory, lootable: Instance)
    if entryExists(lootable) then
        warn("Entry already exists")
        return
    end
    MasterList[lootable] = {
        
    }:: entry
end

type ItemData = {
    tool: Tool,
    worn: boolean?,
    location: {
        SlotGroup: Tool?,
        LayoutOrder: number
    }
}

function LootDataManager.AddItem(lootable, ...: ItemData)
    local args = {...}

    for _, v: ItemData in args do
        if entryExists(lootable) then
            MasterList[lootable][v.tool] = 
        end
    end
end

function LootDataManager.GetData(lootable: Instance): Types_LootData.Regular | Types_LootData.StorageEquipment | Types_LootData.Corpse
    return MasterList[lootable]
end

return LootDataManager