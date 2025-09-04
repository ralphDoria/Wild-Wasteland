
local RS = game:GetService("ReplicatedStorage")
local LootingSystem_Storage = RS.LootingSystem_Storage 
local LootItemsHolding: Folder = LootingSystem_Storage.LootItemsHolding
local LootableInstanceDataReplicators: Folder = LootingSystem_Storage.Remotes.LootableInstanceDataReplicators
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local SharedFunctions = require("./SharedFunctions")
local StandardLootable = require("./StandardLootable")

local remotes = {
    LootedTagReplicatedToClient = LootingSystem_Storage.Remotes.LootedTagReplicatedToClient
}

local CorpseLootable = {}

CorpseLootable.createdObjects = {}:: {[Model]: Types_LootSystem.CorpseLootableObject}

function CorpseLootable.new(lootableInstance: Model, presetData: Types_LootSystem.CorpseFilledSlotsData?): Types_LootSystem.CorpseLootableObject
    local dataChangeReplicator = Instance.new("UnreliableRemoteEvent")
    dataChangeReplicator.Parent = LootableInstanceDataReplicators

    local self: Types_LootSystem.CorpseLootableObject = {
        _itself = lootableInstance,
        Space = 0, -- space will be calculated for in _initialize()
        _numberOfItems = 0,
        FilledSlotsData = CorpseLootable.createEmptyFilledSlotsData(),
        DataChangeReplicatorRemote = dataChangeReplicator
    }

    CorpseLootable._initialize(self, presetData)

    CorpseLootable.createdObjects[lootableInstance] = self
    warn(`Created server CorpseLootale for {lootableInstance}`)
    return self
end

function CorpseLootable.createEmptyFilledSlotsData(): Types_LootSystem.CorpseFilledSlotsData
    local filledSlotsData = {}
    for _, equipmentSlotNumber in Types_LootSystem.EnumEquipmentSlots do
        filledSlotsData[tostring(equipmentSlotNumber)] = {
            equipmentTool = nil,
            slotGroupData = {}
        } 
    end
    return filledSlotsData
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
    local equipmentTool: Tool? = dataChangeRequest.equipmentTool
    local equipmentNumber = dataChangeRequest.equipmentToolLayoutOrder

    local filledSlotsData = self.FilledSlotsData
    local currentEquipmentTool = filledSlotsData[tostring(equipmentNumber)].equipmentTool

    -- make sure equipment slot is still there and it's the same as beofre, then make sure loot tool is still there.
    if currentEquipmentTool == equipmentTool then
        if dataChangeRequest.lootToolLayoutOrder == nil then
            -- equipmentTool is to be replaced
            local substituteTool = dataChangeRequest.substituteTool

            local callbacks: Types_LootSystem.callbacks = {
                takeLoot = function(player: Player)
                    if equipmentTool then
                        if not substituteTool then
                            -- Subtract the number of slots in the equipmentTool's slot group, or the value of the space attribute of the equipment tool
                            local space_equipmentTool: number? = equipmentTool:GetAttribute("Space"):: number?
                            if space_equipmentTool then
                                SharedFunctions.SetNumberOfItems(self, self._numberOfItems - space_equipmentTool)
                            else
                                warn(`{equipmentTool}'s 'Space' attribute not found: this is either an error or tool is not a storage wearable; {self._itself.Name}'s 'Space' attribute remains unchanged.`)
                            end
                        end
                        
                        -- warn(`Adding looted attribute to {equipmentTool}`)
                        local lootedTools = {}
                        equipmentTool:AddTag("IgnoreInventorySlotAutofill")
                        table.insert(lootedTools, equipmentTool)
                        equipmentTool.Parent = player.Backpack
                        local standardLootable: Types_LootSystem.StandardLootableObject = StandardLootable.createdObjects[equipmentTool]
                        if standardLootable then
                            standardLootable.FilledSlotsData = self.FilledSlotsData[tostring(equipmentNumber)].slotGroupData
                            local numberOfItems = 0
                            for _, v in standardLootable.FilledSlotsData do
                                numberOfItems += 1
                                v:AddTag("IgnoreInventorySlotAutofill")
                                table.insert(lootedTools, v)
                                v.Parent = player.Backpack
                            end
                            StandardLootable.SetNumberOfItems(standardLootable, numberOfItems)
                        end
                        
                        local removeLootedTagConnection: RBXScriptConnection
                        removeLootedTagConnection = remotes.LootedTagReplicatedToClient.OnServerEvent:Connect(function(thisPlayer: Player, tool: Tool)  
                            local foundIndex: number? = table.find(lootedTools, tool)
                            if foundIndex then
                                print(`Looted tag served its purpose for {tool}, now removing it`)
                                equipmentTool:RemoveTag("IgnoreInventorySlotAutofill")
                                table.remove(lootedTools, foundIndex)

                                if #lootedTools == 0 then
                                    removeLootedTagConnection:Disconnect()
                                    print("Disconnecting rmeovedLootedTagConnection")
                                end
                            end
                        end)
                    end
                end,
                doSubstitution = function()
                    local equipmentToolAndSlotGroupData = filledSlotsData[tostring(equipmentNumber)]
                    equipmentToolAndSlotGroupData.equipmentTool = substituteTool
                    if substituteTool then
                        local substituteLootableObject: Types_LootSystem.StandardLootableObject = StandardLootable.createdObjects[substituteTool]
                        equipmentToolAndSlotGroupData.slotGroupData = if substituteLootableObject.FilledSlotsData then substituteLootableObject.FilledSlotsData else nil

                        if not equipmentTool then
                            local space_substituteTool: number? = substituteTool:GetAttribute("Space"):: number? 
                            if space_substituteTool then
                                SharedFunctions.SetNumberOfItems(self, self._numberOfItems - space_substituteTool)
                            else
                                warn(`{equipmentTool}'s 'Space' attribute not found: this is either an error or tool is not a storage wearable; {self._itself.Name}'s 'Space' attribute remains unchanged.`)
                            end
                        end

                        substituteTool.Parent = LootItemsHolding
                    else
                        equipmentToolAndSlotGroupData.slotGroupData = {}
                    end

                    local changeReplicator = self.DataChangeReplicatorRemote
                    changeReplicator:FireAllClients(dataChangeRequest)
                end
            }
            return callbacks
        else
            -- loot tool in specified location is to be replaced 
            return SharedFunctions.standardValidate(self, dataChangeRequest)
        end
    end

    print("returning nil")
    return nil
end

function CorpseLootable.processDataChangeRequest(self: Types_LootSystem.CorpseLootableObject, player: Player, changeRequests: {Types_LootSystem.CorpseDataChangeRequest})
    print("Before:")
    print(self.FilledSlotsData)
    local result = SharedFunctions.processDataChangeRequest(CorpseLootable._validate, self, player, changeRequests)
    print("After:")
    print(self.FilledSlotsData)
    return result
end

function CorpseLootable.Destroy(self: Types_LootSystem.CorpseLootableObject)
    self.DataChangeReplicatorRemote:Destroy()
    CorpseLootable.createdObjects[self._itself] = nil
    table.clear(self)
end

return CorpseLootable