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

local CorpseLootable = {}

CorpseLootable.createdObjects = {}:: {[Model]: Types_LootSystem.CorpseLootableObject}

function CorpseLootable.new(lootableInstance: Model, space: number, presetData: Types_LootSystem.CorpseFilledSlotsData?): Types_LootSystem.CorpseLootableObject
    local dataChangeReplicator = Instance.new("RemoteEvent")
    dataChangeReplicator.Parent = LootableInstanceDataReplicators

    local self: Types_LootSystem.CorpseLootableObject = {
        _itself = lootableInstance,
        Space = space,
        _numberOfItems = 0,
        FilledSlotsData = {},
        DataChangeReplicatorRemote = dataChangeReplicator
    }

    CorpseLootable._initialize(self, presetData)

    CorpseLootable.createdObjects[lootableInstance] = self
    return self
end

function CorpseLootable._initialize(self: Types_LootSystem.CorpseLootableObject, presetData: Types_LootSystem.CorpseFilledSlotsData?)
    self._itself:SetAttribute("isEmpty_server", true) -- initial value

    if presetData then
        self.FilledSlotsData = presetData
        local numberOfItems = 0
        for string_equipmentSlotNumber: string, equipmentToolAndSlotGroupData: {equipmentTool: Tool?, slotGroupData: Types_LootSystem.StandardFilledSlotsData} in presetData do
            if Types_LootSystem.getEquipmentSlotName(tonumber(string_equipmentSlotNumber):: number) then
                for _, tool: Tool? in equipmentToolAndSlotGroupData.slotGroupData do
                    if tool then
                        numberOfItems += 1
                    end
                end
            end
        end
        SharedFunctions.SetNumberOfItems(self, numberOfItems)
    end
end

function CorpseLootable._validate(self: Types_LootSystem.CorpseLootableObject, dataChangeRequest: Types_LootSystem.CorpseDataChangeRequest): Types_LootSystem.callbacks?
    local equipmentTool = dataChangeRequest.equipmentTool
    local lootTool = dataChangeRequest.lootTool
    local substituteTool = dataChangeRequest.substituteTool

    local equipmentNumber = dataChangeRequest.equipmentToolLayoutOrder
    local lootNumber = dataChangeRequest.lootToolLayoutOrder

    local filledSlotsData = self.FilledSlotsData
    local currentEquipmentTool = filledSlotsData[tostring(equipmentNumber)].equipmentTool
    local slotGroupData = filledSlotsData[tostring(equipmentNumber)].slotGroupData

    -- make sure equipment slot is still there and it's the same as beofre, then make sure loot tool is still there.
    local isValidEquipmentNumber: boolean = Types_LootSystem.EnumEquipmentSlots[equipmentNumber] ~= nil
    if isValidEquipmentNumber and self.FilledSlotsData[tostring(equipmentNumber)].equipmentTool == dataChangeRequest.equipmentTool then
        if dataChangeRequest.lootToolLayoutOrder == nil then
            -- equipmentTool is to be replaced
            error("WIP, CorpseLootable's afterValidation now will cause unexpected behavior")
            if currentEquipmentTool == dataChangeRequest.equipmentTool then
                local callbacks: Types_LootSystem.callbacks = {
                    takeLoot = function(player: Player)
                        if lootTool then
                            if not substituteTool then
                                SharedFunctions.SetNumberOfItems(serverLootableObject, serverLootableObject._numberOfItems - 1)
                            end
                            
                            -- warn(`Adding looted attribute to {lootTool}`)
                            lootTool:AddTag("Looted")
                            lootTool.Parent = player.Backpack
                            remotes.LootedTagReplicatedToClient.OnServerEvent:Once(function(thisPlayer: Player, tool: Tool)  
                                if tool == lootTool then
                                    warn("Looting tag replicated successfully, now removing it")
                                    lootTool:RemoveTag("Looted")                    
                                end
                            end)
                        end
                    end,
                    doSubstitution = function()
                        slotGroupData[tostring(slotNumber)] = substituteTool

                        if substituteTool then
                            if not lootTool then
                                SharedFunctions.SetNumberOfItems(serverLootableObject, serverLootableObject._numberOfItems + 1)
                            end

                            substituteTool.Parent = LootItemsHolding
                        end

                        local changeReplicator = serverLootableObject.DataChangeReplicatorRemote
                        changeReplicator:FireAllClients(dataChangeRequest)
                    end
                }
                return callbacks
            end
        else
            -- loot tool in specified location is to be replaced 
            return SharedFunctions.standardValidate(self, dataChangeRequest)
        end
    end

    return nil
end

function CorpseLootable.processDataChangeRequest(self: Types_LootSystem.CorpseLootableObject, player: Player, changeRequests: {Types_LootSystem.CorpseDataChangeRequest})
    local result = SharedFunctions.processDataChangeRequest(CorpseLootable._validate, self, player, changeRequests)
    return result
end

function CorpseLootable.Destroy(self: Types_LootSystem.CorpseLootableObject)
    self.DataChangeReplicatorRemote:Destroy()
    CorpseLootable.createdObjects[self._itself] = nil
    table.clear(self)
end

return CorpseLootable