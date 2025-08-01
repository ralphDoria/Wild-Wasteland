--!strict

local RS = game:GetService("ReplicatedStorage")
local LootingSystem_Storage = RS.LootingSystem_Storage 
local LootItemsHolding: Folder = LootingSystem_Storage.LootItemsHolding
local LootableInstanceDataReplicators: Folder = LootingSystem_Storage.Remotes.LootableInstanceDataReplicators
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)

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

local function findValueInDictionary(dictionary: {any: any}, value: any)
    for _, v in dictionary do
        if v == value then
            return true
        end
    end
    return false
end

function CorpseLootable._initialize(self: Types_LootSystem.CorpseLootableObject, presetData: Types_LootSystem.CorpseFilledSlotsData?)
    self._itself:SetAttribute("isEmpty_server", true) -- initial value

    if presetData then
        self.FilledSlotsData = presetData
        local numberOfItems = 0
        for equipmentSlotString: string, equipmentToolAndSlotGroupData: {equipmentTool: Tool?, slotGroupData: Types_LootSystem.StandardFilledSlotsData} in presetData do
            if findValueInDictionary(Types_LootSystem.EnumEquipmentSlots, tonumber(equipmentSlotString)) then
                for _, tool: Tool? in equipmentToolAndSlotGroupData.slotGroupData do
                    if tool then
                        numberOfItems += 1
                    end
                end
            end
        end
        CorpseLootable.SetNumberOfItems(self, numberOfItems)
    end
end

function CorpseLootable.SetNumberOfItems(self: Types_LootSystem.CorpseLootableObject, num: number)
    self._numberOfItems = num
    local isEmpty = num == 0
    local instance = self._itself
    local currentValue = instance:GetAttribute("isEmpty_server")
    if currentValue ~= isEmpty then
        instance:SetAttribute("isEmpty_server", isEmpty)
    end
end

local function validate(self: Types_LootSystem.CorpseLootableObject, dataChangeRequestPacket: Types_LootSystem.CorpseDataChangeRequestPacket): ((player: Player) -> ())?
    local equipmentTool = dataChangeRequestPacket.equipmentTool
    local lootTool = dataChangeRequestPacket.lootTool
    local substituteTool = dataChangeRequestPacket.substituteTool

    local equipmentNumber = dataChangeRequestPacket.equipmentToolLayoutOrder
    local lootNumber = dataChangeRequestPacket.lootToolLayoutOrder

    local filledSlotsData = self.FilledSlotsData
    local currentEquipmentTool = filledSlotsData[tostring(equipmentNumber)].equipmentTool
    local slotGroupData = filledSlotsData[tostring(equipmentNumber)].slotGroupData

    -- make sure equipment slot is still there and it's the same as beofre, then make sure loot tool is still there.
    local isValidEquipmentNumber: boolean = Types_LootSystem.EnumEquipmentSlots[equipmentNumber] ~= nil
    if isValidEquipmentNumber and self.FilledSlotsData[tostring(equipmentNumber)].equipmentTool == dataChangeRequestPacket.equipmentTool then
        if dataChangeRequestPacket.lootTool == nil and dataChangeRequestPacket.lootToolLayoutOrder == nil then
            -- equipmentTool is to be replaced
        else
            -- loot tool in specified location is to be replaced 
            local currentLootTool = slotGroupData[tostring(lootNumber)]
            if currentLootTool == lootTool then
                local function afterValidation(player: Player)
                    local changeReplicator = self.DataChangeReplicatorRemote
                    slotGroupData[tostring(lootNumber)] = substituteTool

                    if substituteTool then
                        if not lootTool then
                            CorpseLootable.SetNumberOfItems(self, self._numberOfItems + 1)
                        end

                        substituteTool.Parent = LootItemsHolding
                    end

                    if lootTool then
                        if not substituteTool then
                            CorpseLootable.SetNumberOfItems(self, self._numberOfItems - 1)
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
                    changeReplicator:FireAllClients(dataChangeRequestPacket.lootToolLayoutOrder, substituteTool, lootTool)
                end
                return afterValidation
            else
                warn(`Failed state validation because {currentLootTool} ~= {lootTool}`)
                return nil
            end
        end
    end
end

function CorpseLootable.makeDataChange(self: Types_LootSystem.CorpseLootableObject, player: Player, changeRequests: {Types_LootSystem.CorpseDataChangeRequestPacket})
    local afterAllValidatedCallbacks = {}

    for _, changeRequest in changeRequests do
        local result = validate(self, changeRequest)
        if result then
            table.insert(afterAllValidatedCallbacks, result)
        else
            return false
        end
    end

    for _, v in afterAllValidatedCallbacks do
        v(player)
    end
    return true
    
end

function CorpseLootable.Destroy(self: Types_LootSystem.CorpseLootableObject)
    self.DataChangeReplicatorRemote:Destroy()
    CorpseLootable.createdObjects[self._itself] = nil
    table.clear(self)
end

return CorpseLootable