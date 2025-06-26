--!strict

local RS = game:GetService("ReplicatedStorage")
local LootItemsHolding: Folder = RS.LootingSystem_Storage.LootItemsHolding
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)

local StandardLootable = {}

function StandardLootable.new(space: number, ...: Types_LootSystem.itemEntry): Types_LootSystem.StandardLootableObject
    local self: Types_LootSystem.StandardLootableObject = {
        Space = space,
        items = {}  
    }

    StandardLootable._initialize(self)

    return self
end

function StandardLootable._initialize(self: Types_LootSystem.StandardLootableObject)
    local items = self.items
    for i = 1, self.Space do
        items[i] = {
            tool = nil,
            isGrabbed = false
        }
    end
end

local function validate(self: Types_LootSystem.StandardLootableObject, dataChangeRequestPacket: Types_LootSystem.dataChangeRequestPacket): ((Player, RemoteEvent) -> ())?
    local lootTool = dataChangeRequestPacket.syncCheck
    local newTool = dataChangeRequestPacket.newTool
    local currentSlotData = self.items[dataChangeRequestPacket.LayoutOrder]
    if currentSlotData.tool == lootTool then
        local function afterValidation(player: Player, changeReplicator: RemoteEvent)
            currentSlotData.tool = newTool
            if newTool then 
                newTool.Parent = LootItemsHolding
            end
            if lootTool then
                warn(`Adding looted tag to {lootTool}`)
                lootTool:AddTag("Looted")
                lootTool.Parent = player.Backpack
                local connection
                connection = changeReplicator.OnServerEvent:Connect(function(a0: Player, thisTool: Tool)  
                    if thisTool == lootTool then
                        connection:Disconnect()
                        warn(`{lootTool} successfully circumvented ItemMovementTracker's onAdded, removing tag`)
                        lootTool:RemoveTag("Looted")
                    end
                end)
            end
            changeReplicator:FireAllClients(dataChangeRequestPacket.LayoutOrder, newTool, lootTool)
        end
        return afterValidation
    else
        warn(`Failed state validation: {currentSlotData.tool} ~= {lootTool}... newTool: {newTool}`)
        return nil
    end
end

function StandardLootable.makeDataChange(player: Player, self: Types_LootSystem.StandardLootableObject, changeRequests: {Types_LootSystem.dataChangeRequestPacket}, changeReplicator: RemoteEvent)
    -- local lootTool = dataChangeRequestPacket.syncCheck
    -- local newTool = dataChangeRequestPacket.newTool
    -- local currentSlotData = self.items[dataChangeRequestPacket.LayoutOrder]
    -- if currentSlotData.tool == lootTool then
    --     currentSlotData.tool = newTool
    --     if newTool then 
    --         newTool.Parent = LootItemsHolding
    --     end
    --     if lootTool then
    --         warn(`Adding looted tag to {lootTool}`)
    --         lootTool:AddTag("Looted")
    --         lootTool.Parent = player.Backpack
    --         local connection
    --         connection = changeReplicator.OnServerEvent:Connect(function(a0: Player, thisTool: Tool)  
    --             if thisTool == lootTool then
    --                 connection:Disconnect()
    --                 warn(`{lootTool} successfully circumvented ItemMovementTracker's onAdded, removing tag`)
    --                 lootTool:RemoveTag("Looted")
    --             end
    --         end)
    --     end
    --     changeReplicator:FireAllClients(dataChangeRequestPacket.LayoutOrder, newTool, lootTool)
    --     return true
    -- else
    --     return false
    -- end

    local afterAllValidatedCallbacks = {}

    for _, v in changeRequests do
        local result = validate(self, v)
        if result then
            table.insert(afterAllValidatedCallbacks, result)
        else
            return false
        end
    end

    for _, v in afterAllValidatedCallbacks do
        print("calling callback")
        v(player, changeReplicator)
    end
    return true
    
end

function StandardLootable.Destroy(self: Types_LootSystem.StandardLootableObject)
    table.clear(self)
end

return StandardLootable