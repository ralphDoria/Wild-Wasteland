--!strict
-- local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local handleTaggedInstances = require(ReplicatedStorage.RojoManaged_RS.Utility.handleTaggedInstances)
local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local TAGS_LOOT = require(InventoryScriptStorage.LootingSection.Components.TAGS_LOOT)
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)

local LootingSystem_Server = game:GetService("ServerScriptService").RojoManaged_SSS.LootingSystem_Server
local StandardLootable = require(LootingSystem_Server.Components.StandardLootable)
local CorpseLootable = require(LootingSystem_Server.Components.CorpseLootable)
local LootToolsDestructionTracker = require(LootingSystem_Server.Components.LootToolsDestructionTracker)

local LootingSystem_Storage = ReplicatedStorage.LootingSystem_Storage
local LootItemsHolding = LootingSystem_Storage.LootItemsHolding

local rfn: {[string] : RemoteFunction} = {
    GetChangeReplicatorRemote = LootingSystem_Storage.Remotes.GetChangeReplicatorRemote,
    GetLootData = LootingSystem_Storage.Remotes.GetLootData,
    TrySlotInteraction = LootingSystem_Storage.Remotes.TrySlotInteraction,
    OverrideItemData = LootingSystem_Storage.Remotes.OverrideItemData
}

local remotes = {
    SendClientCorpseFilledSlotsData = LootingSystem_Storage.Remotes.SendClientCorpseFilledSlotsData:: RemoteEvent,
    moveToolsToLootItemsHolding = LootingSystem_Storage.Remotes.MoveToolsToLootItemsHolding:: RemoteEvent,
}

local LootDataService = {
    initialized = false
}

local standardLootableObjects = StandardLootable.createdObjects
local corpseLootableObjects = CorpseLootable.createdObjects
local function getStandardLootable(lootableInstance)
    return standardLootableObjects[lootableInstance]
end
local function getCorpseLootable(lootableInstance)
    return corpseLootableObjects[lootableInstance]
end

function LootDataService.init()
    local connections = handleTaggedInstances(
        TAGS_LOOT.STANDARD_LOOTABLE, 
        function(taggedInstance: Instance)
            local space: number
            if taggedInstance:HasTag("StorageWearable") then
                space = taggedInstance:GetAttribute("Space"):: number
                if space == nil then
                    error(`{taggedInstance.Name} is missing attribute "Space"`)
                end
            else
                space = 20
            end
            StandardLootable.new(taggedInstance:: Model | Tool, space)
        end,
        function(taggedInstance: Instance)  
            StandardLootable.Destroy(StandardLootable.createdObjects[taggedInstance:: Model | Tool])
        end
    )

    -- when a player dies, they will send over their corpse data
    remotes.SendClientCorpseFilledSlotsData.OnServerEvent:Connect(function(player: Player, corpseFilledSlotsData: Types_LootSystem.CorpseFilledSlotsData, hrp: BasePart)
        warn(`Creating server CorpseLootable for {player.Name}`)
        CorpseLootable.new(hrp:: any, corpseFilledSlotsData)
        hrp:AddTag(TAGS_LOOT.CORPSE_LOOTABLE)
    end)

    remotes.moveToolsToLootItemsHolding.OnServerEvent:Connect(function(player: Player, corpseCharacter: Model)
        local function setCorpseCharacter(tool, char)
            local objValueName: string = "CorpseCharacterValue"

            local existingObjValue = tool:FindFirstChild(objValueName):: ObjectValue
            if existingObjValue then
                existingObjValue.Value = corpseCharacter
            else
                local objectValue = Instance.new("ObjectValue")
                objectValue.Name = objValueName
                objectValue.Value = char
                objectValue.Parent = tool
            end
        end

        local backpack = player.Backpack
        for _, v in backpack:GetChildren() do 
            if v:IsA("Tool") then
                setCorpseCharacter(v, corpseCharacter)
                v.Parent = LootItemsHolding
            elseif v:IsA("Folder") then
                for _, v in v:GetDescendants() do
                    if v:IsA("Tool") then
                        setCorpseCharacter(v, corpseCharacter)
                        v.Parent = LootItemsHolding
                    end
                end
            end
        end
    end)

    rfn.GetLootData.OnServerInvoke = function(player, lootableInstance: Model | Tool): Types_LootSystem.StandardFilledSlotsData
        -- warn("Sending filledSlotsData from server: ")
        -- warn(StandardLootable.createdObjects[lootableInstance].FilledSlotsData)
        return if getStandardLootable(lootableInstance) then getStandardLootable(lootableInstance).FilledSlotsData else getCorpseLootable(lootableInstance).FilledSlotsData
    end

    rfn.TrySlotInteraction.OnServerInvoke = function(player, lootableInstance: Model | Tool, changeRequests: any)
        local standardLootable = StandardLootable.createdObjects[lootableInstance]
        local corpseLootable = CorpseLootable.createdObjects[lootableInstance]

        if not standardLootable and not corpseLootable then
            warn(`{lootableInstance} is not registered as a standard or corpse lootable.`)
            return false
        end
        
        print(player)
        if corpseLootable then
            local success: boolean = CorpseLootable.processDataChangeRequest(corpseLootable, player, changeRequests:: Types_LootSystem.CorpseDataChangeRequest)
            return success
        else
            local success: boolean = StandardLootable.processDataChangeRequest(standardLootable:: Types_LootSystem.StandardLootableObject, player, changeRequests:: Types_LootSystem.StandardDataChangeRequest)
            return success
        end
    end

    rfn.OverrideItemData.OnServerInvoke = function(player, lootableInstance: Model | Tool, filledSlotsData: Types_LootSystem.StandardFilledSlotsData)
        local lootableObject = StandardLootable.createdObjects[lootableInstance]
        lootableObject.FilledSlotsData = filledSlotsData
        local numberOfItems = 0
        for _, v in filledSlotsData do
            if v then
                numberOfItems += 1
            end
        end
        StandardLootable.SetNumberOfItems(lootableObject, numberOfItems)
        return true
    end

    LootDataService.initialized = true

    rfn.GetChangeReplicatorRemote.OnServerInvoke = function(player, lootableInstance: Tool | Model): UnreliableRemoteEvent
        while getStandardLootable(lootableInstance) == nil and getCorpseLootable(lootableInstance) == nil do
            task.wait()
            print(`Waiting for {lootableInstance} to be initialized on the server`)
        end
        return if getStandardLootable(lootableInstance) then getStandardLootable(lootableInstance).DataChangeReplicatorRemote else getCorpseLootable(lootableInstance).DataChangeReplicatorRemote
    end

    LootToolsDestructionTracker.ToolDestroyed:Connect(function(tool: Tool, lootableInstance: Tool)
        warn(`SERVER CALLING PROCESS DATA CHANGE REQUEST TO EMPTY DESTROYED LOOT TOOL'S  ({tool.Name})SLOT`)
        local standardLootable = StandardLootable.createdObjects[lootableInstance]
        local corpseLootable = CorpseLootable.createdObjects[lootableInstance]
        assert(corpseLootable or standardLootableObjects, "Could not find lootalbe associated with tool")

        if corpseLootable then
            local equipmentLayoutOrder, toolLayoutOrder = CorpseLootable.getEquipmentAndToolLayoutOrders(corpseLootable.FilledSlotsData, tool)
            if not equipmentLayoutOrder or not toolLayoutOrder then warn("Couldn't locate destroyed tool in corpse lootable") return end

            CorpseLootable.processDataChangeRequest(corpseLootable, nil, --setting the player argument as nil is ok here because loot tool will be nil
                {
                    {
                        __type = Types_LootSystem.EnumLootableTypes.Corpse,
                        lootToolLayoutOrder = toolLayoutOrder,
                        lootTool = tool,
                        substituteTool = nil,
                        equipmentToolLayoutOrder = equipmentLayoutOrder,
                        equipmentTool = corpseLootable.FilledSlotsData[tostring(equipmentLayoutOrder)].equipmentTool:: Tool
                    }
                }
            )
        else
            print(`Indexed Table: {standardLootable}`)
            local toolLayoutOrder: number? = StandardLootable.getToolLayoutOrder(standardLootable.FilledSlotsData, tool)
            if not toolLayoutOrder then warn("couldn't locate destroyed tool in standard lootable") return end

            StandardLootable.processDataChangeRequest(standardLootable, nil, 
                {
                    {
                        __type = Types_LootSystem.EnumLootableTypes.Standard,
                        lootToolLayoutOrder = toolLayoutOrder,
                        lootTool = tool,
                        substituteTool = nil,
                        equipmentToolLayoutOrder = nil,
                        equipmentTool = nil
                    }
                }
            )
        end

    end)
end

return LootDataService