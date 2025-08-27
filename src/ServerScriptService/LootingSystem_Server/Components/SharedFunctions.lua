local RS = game:GetService("ReplicatedStorage")
local LootingSystem_Storage = RS.LootingSystem_Storage 
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local LootedTagReplicatedToClient = LootingSystem_Storage.Remotes.LootedTagReplicatedToClient
local LootItemsHolding: Folder = LootingSystem_Storage.LootItemsHolding

local SharedFunctions = {}

function SharedFunctions.SetNumberOfItems(serverLootableObject: any, num: number)
    serverLootableObject._numberOfItems = num
    local isEmpty = num == 0
    local instance = serverLootableObject._itself
    local currentValue = instance:GetAttribute("isEmpty_server")
    if currentValue ~= isEmpty then
        instance:SetAttribute("isEmpty_server", isEmpty)
    end
end

function SharedFunctions.standardValidate(serverLootableObject: any, dataChangeRequest: any): Types_LootSystem.callbacks?

    local FilledSlotsData = serverLootableObject.FilledSlotsData
    local slotGroupData = if Types_LootSystem.isCorpseFilledSlotsDataType(FilledSlotsData) then FilledSlotsData[tostring(dataChangeRequest.equipmentToolLayoutOrder)].slotGroupData else FilledSlotsData
    
    
    local lootTool = dataChangeRequest.lootTool
    local substituteTool = dataChangeRequest.substituteTool
    local slotNumber = dataChangeRequest.lootToolLayoutOrder
    local currentLootTool = slotGroupData[tostring(slotNumber)]
    if currentLootTool == lootTool then
        local callbacks: Types_LootSystem.callbacks = {
            takeLoot = function(player: Player)
                if lootTool then
                    if not substituteTool then
                        SharedFunctions.SetNumberOfItems(serverLootableObject, serverLootableObject._numberOfItems - 1)
                    end
                    
                    -- warn(`Adding looted attribute to {lootTool}`)
                    lootTool:AddTag("Looted")
                    lootTool.Parent = player.Backpack
                    LootedTagReplicatedToClient.OnServerEvent:Once(function(thisPlayer: Player, tool: Tool)  
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
    else
        warn(`Failed state validation because {currentLootTool} ~= {lootTool}`)
        return nil
    end
end

function SharedFunctions.processDataChangeRequest(validate: (serverLootableObject: any, dataChangeRequest: any) -> Types_LootSystem.callbacks?, serverLootableObject: any, player: Player, changeRequests: any)
    local callbacks_to_run_if_all_requests_validated: {Types_LootSystem.callbacks} = {}

    for _, dataChangeRequest in changeRequests do
        local callbacks = validate(serverLootableObject, dataChangeRequest):: Types_LootSystem.callbacks
        if callbacks then
            table.insert(callbacks_to_run_if_all_requests_validated, callbacks)
        else
            return false
        end
    end

    print("CHANGE REQUESTS PASSED VALIDATION")
    --[[
        Callback are split into two parts, takeLoot() and doSubstitution(), because the substitution needs to be done after all loot has been taken to ensure that when
        two loot slots are swapped, one of the loot tools doesn't end up in the player's backpack (bug) rather than both being in the LootItemsHolding folder. 
    ]]
    for _, v: Types_LootSystem.callbacks in callbacks_to_run_if_all_requests_validated do
        v.takeLoot(player)
    end
    for _, v: Types_LootSystem.callbacks in callbacks_to_run_if_all_requests_validated do
       v.doSubstitution() 
    end
    return true
end

return SharedFunctions