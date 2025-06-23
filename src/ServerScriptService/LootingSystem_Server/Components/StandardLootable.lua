--!strict

local RS = game:GetService("ReplicatedStorage")
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)

local StandardLootable = {}

function StandardLootable.new(space: number, ...: Types_LootSystem.itemEntry): Types_LootSystem.StandardLootableObject
    local self: Types_LootSystem.StandardLootableObject = {
        Space = space,
        items = {}  
    }


    StandardLootable.AddItems(self, ...)

    return self
end

function StandardLootable.AddItems(self: Types_LootSystem.StandardLootableObject, ...: Types_LootSystem.itemEntry): nil | {}
    local items = self.items
    local args = {...}
    local failedToInsert = {}
    for _, v in args do
        if items[v.tool] == nil then
            items[v.tool] = {
                LayoutOrder = v.LayoutOrder,
                isGrabbed = false
            }
        else
            warn(`Failed to insert {v.tool} into slot #{v.LayoutOrder} because it's already occupied by {items[v.LayoutOrder]}`)
            table.insert(failedToInsert, v)
        end
    end

    if #failedToInsert > 0 then
        return failedToInsert
    else
        return nil
    end
end

function StandardLootable.RemoveItems(self: Types_LootSystem.StandardLootableObject, ...: Tool)
    local items = self.items
    local args = {...}
    for _, v in args do
        if items[v] then
            items[v] = nil
        end
    end
end

function StandardLootable.Destroy(self: Types_LootSystem.StandardLootableObject)
    table.clear(self)
end

return StandardLootable