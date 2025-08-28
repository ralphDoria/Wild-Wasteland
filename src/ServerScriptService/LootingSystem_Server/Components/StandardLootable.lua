--!strict

local RS = game:GetService("ReplicatedStorage")
local LootingSystem_Storage = RS.LootingSystem_Storage 
local LootItemsHolding: Folder = LootingSystem_Storage.LootItemsHolding
local LootableInstanceDataReplicators: Folder = LootingSystem_Storage.Remotes.LootableInstanceDataReplicators
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local SharedFunctions = require("./SharedFunctions")

local remotes = {
    LootedTagReplicatedToClient = LootingSystem_Storage.Remotes.LootedTagReplicatedToClient
}

local StandardLootable = {}

StandardLootable.createdObjects = {}:: {[Model | Tool]: Types_LootSystem.StandardLootableObject}

function StandardLootable.new(lootableInstance: Model | Tool, space: number, presetData: Types_LootSystem.StandardFilledSlotsData?): Types_LootSystem.StandardLootableObject
    local dataChangeReplicator = Instance.new("UnreliableRemoteEvent")
    dataChangeReplicator.Parent = LootableInstanceDataReplicators

    local self: Types_LootSystem.StandardLootableObject = {
        _itself = lootableInstance,
        Space = space,
        _numberOfItems = 0,
        FilledSlotsData = {},
        DataChangeReplicatorRemote = dataChangeReplicator
    }

    StandardLootable._initialize(self, presetData)

    StandardLootable.createdObjects[lootableInstance] = self
    return self
end

function StandardLootable._initialize(self: Types_LootSystem.StandardLootableObject, presetData: Types_LootSystem.StandardFilledSlotsData?)
    self._itself:SetAttribute("isEmpty_server", true) -- initial value

    if presetData then
        self.FilledSlotsData = presetData
        local numberOfItems = 0
        for _, tool: Tool? in presetData do
            if tool then
                numberOfItems += 1
            end
        end
        SharedFunctions.SetNumberOfItems(self, numberOfItems)
    end
end

function StandardLootable.SetNumberOfItems(self: Types_LootSystem.StandardLootableObject, num: number)
    SharedFunctions.SetNumberOfItems(self, num)
end

function StandardLootable.processDataChangeRequest(self: Types_LootSystem.StandardLootableObject, player: Player, changeRequests: {Types_LootSystem.StandardDataChangeRequest})
    local result = SharedFunctions.processDataChangeRequest(SharedFunctions.standardValidate, self, player, changeRequests)
    return result
end

function StandardLootable.Destroy(self: Types_LootSystem.StandardLootableObject)
    self.DataChangeReplicatorRemote:Destroy()
    StandardLootable.createdObjects[self._itself] = nil
    table.clear(self)
end

return StandardLootable