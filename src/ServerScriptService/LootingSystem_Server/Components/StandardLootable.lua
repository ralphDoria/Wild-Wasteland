--!strict

local RS = game:GetService("ReplicatedStorage")
local LootingSystem_Storage = RS.LootingSystem_Storage 
local LootItemsHolding: Folder = LootingSystem_Storage.LootItemsHolding
local LootableInstanceDataReplicators: Folder = LootingSystem_Storage.Remotes.LootableInstanceDataReplicators
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)

local remotes = {
    LootedTagReplicatedToClient = LootingSystem_Storage.Remotes.LootedTagReplicatedToClient
}

local StandardLootable = {}

StandardLootable.createdObjects = {}:: {[Model | Tool]: Types_LootSystem.StandardLootableObject}

function StandardLootable.new(lootableInstance: Model | Tool, space: number, presetData: Types_LootSystem.StandardFilledSlotsData?): Types_LootSystem.StandardLootableObject
    local dataChangeReplicator = Instance.new("RemoteEvent")
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
        StandardLootable.SetNumberOfItems(self, numberOfItems)
    end
end

function StandardLootable.SetNumberOfItems(self: Types_LootSystem.StandardLootableObject, num: number)
    self._numberOfItems = num
    local isEmpty = num == 0
    local instance = self._itself
    local currentValue = instance:GetAttribute("isEmpty_server")
    if currentValue ~= isEmpty then
        instance:SetAttribute("isEmpty_server", isEmpty)
    end
end

local function validate(self: Types_LootSystem.StandardLootableObject, dataChangeRequestPacket: Types_LootSystem.StandardDataChangeRequestPacket): ((player: Player) -> ())?
    local lootTool = dataChangeRequestPacket.lootTool
    local substituteTool = dataChangeRequestPacket.substituteTool
    local slotNumber = dataChangeRequestPacket.lootToolLayoutOrder
    local filledSlotsData = self.FilledSlotsData
    local currentLootTool = filledSlotsData[tostring(slotNumber)]
    if currentLootTool == lootTool then
        local function afterValidation(player: Player)
            local changeReplicator = self.DataChangeReplicatorRemote
            filledSlotsData[tostring(slotNumber)] = substituteTool

            if substituteTool then
                if not lootTool then
                    StandardLootable.SetNumberOfItems(self, self._numberOfItems + 1)
                end

                substituteTool.Parent = LootItemsHolding
            end

            if lootTool then
                if not substituteTool then
                    StandardLootable.SetNumberOfItems(self, self._numberOfItems - 1)
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

function StandardLootable.makeDataChange(self: Types_LootSystem.StandardLootableObject, player: Player, changeRequests: {Types_LootSystem.StandardDataChangeRequestPacket})
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

function StandardLootable.Destroy(self: Types_LootSystem.StandardLootableObject)
    self.DataChangeReplicatorRemote:Destroy()
    StandardLootable.createdObjects[self._itself] = nil
    table.clear(self)
end

return StandardLootable