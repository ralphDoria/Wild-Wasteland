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

type callbacks = {
    takeLoot: (Player) -> (),
    doSubstitution: () -> ()
}

local function validate(self: Types_LootSystem.StandardLootableObject, dataChangeRequest: Types_LootSystem.StandardDataChangeRequest): callbacks?
    local lootTool = dataChangeRequest.lootTool
    local substituteTool = dataChangeRequest.substituteTool
    local slotNumber = dataChangeRequest.lootToolLayoutOrder
    local filledSlotsData = self.FilledSlotsData
    local currentLootTool = filledSlotsData[tostring(slotNumber)]
    if currentLootTool == lootTool then
        local callbacks: callbacks = {
            takeLoot = function(player: Player)
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
            end,
            doSubstitution = function()
                filledSlotsData[tostring(slotNumber)] = substituteTool

                if substituteTool then
                    if not lootTool then
                        StandardLootable.SetNumberOfItems(self, self._numberOfItems + 1)
                    end

                    substituteTool.Parent = LootItemsHolding
                end

                local changeReplicator = self.DataChangeReplicatorRemote
                changeReplicator:FireAllClients(dataChangeRequest)
            end
        }
        return callbacks
    else
        warn(`Failed state validation because {currentLootTool} ~= {lootTool}`)
        return nil
    end
end

function StandardLootable.processDataChangeRequest(self: Types_LootSystem.StandardLootableObject, player: Player, changeRequests: {Types_LootSystem.StandardDataChangeRequest})
    local callbacks_to_run_if_all_requests_validated: {callbacks} = {}

    for _, dataChangeRequest in changeRequests do
        local callbacks = validate(self, dataChangeRequest):: callbacks
        if callbacks then
            table.insert(callbacks_to_run_if_all_requests_validated, callbacks)
        else
            return false
        end
    end

    --[[
        Callback are split into two parts, takeLoot() and doSubstitution(), because the substitution needs to be done after all loot has been taken to ensure that when
        two loot slots are swapped, one of the loot tools doesn't end up in the player's backpack (bug) rather than both being in the LootItemsHolding folder. 
    ]]
    for _, v: callbacks in callbacks_to_run_if_all_requests_validated do
        v.takeLoot(player)
    end
    for _, v: callbacks in callbacks_to_run_if_all_requests_validated do
       v.doSubstitution() 
    end
    return true
    
end

function StandardLootable.Destroy(self: Types_LootSystem.StandardLootableObject)
    self.DataChangeReplicatorRemote:Destroy()
    StandardLootable.createdObjects[self._itself] = nil
    table.clear(self)
end

return StandardLootable