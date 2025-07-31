--!strict
-- local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local handleTaggedInstances = require(ReplicatedStorage.RojoManaged_RS.Utility.handleTaggedInstances)
local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local TAGS_LOOT = require(InventoryScriptStorage.LootingSection.Components.TAGS_LOOT)
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)

local LootingSystem_Server = game:GetService("ServerScriptService").RojoManaged_SSS.LootingSystem_Server
local StandardLootable = require(LootingSystem_Server.Components.StandardLootable)

local LootingSystem_Storage = ReplicatedStorage.LootingSystem_Storage

local rfn: {[string] : RemoteFunction} = {
    GetChangeReplicatorRemote = LootingSystem_Storage.Remotes.GetChangeReplicatorRemote,
    GetLootData = LootingSystem_Storage.Remotes.GetLootData,
    TrySlotInteraction = LootingSystem_Storage.Remotes.TrySlotInteraction,
    OverrideItemData = LootingSystem_Storage.Remotes.OverrideItemData
}

local LootDataService = {
    initialized = false
}

function LootDataService.init()
    local connections = handleTaggedInstances(TAGS_LOOT.STANDARD_CONTAINER, 
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

    rfn.GetLootData.OnServerInvoke = function(player, lootableInstance: Model | Tool): Types_LootSystem.StandardFilledSlotsData
        -- warn("Sending filledSlotsData from server: ")
        -- warn(StandardLootable.createdObjects[lootableInstance].FilledSlotsData)
        return StandardLootable.createdObjects[lootableInstance].FilledSlotsData
    end

    rfn.TrySlotInteraction.OnServerInvoke = function(player, lootableInstance: Model | Tool, changeRequests: {Types_LootSystem.StandardDataChangeRequestPacket})
        local standardLootable = StandardLootable.createdObjects[lootableInstance]
        print(`StandardLootale: {standardLootable}`)
        if not standardLootable then
            warn(`{lootableInstance} is not registered.`)
            return false
        end
        local success: boolean = StandardLootable.makeDataChange(standardLootable, player, changeRequests)
        return success
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

    rfn.GetChangeReplicatorRemote.OnServerInvoke = function(player, lootableInstance: Tool | Model): RemoteEvent
        local standardLootableObjects = StandardLootable.createdObjects
        while standardLootableObjects[lootableInstance] == nil do
            task.wait()
            print(`Waiting for {Instance} to be initialized on the server`)
        end
        return standardLootableObjects[lootableInstance].DataChangeReplicatorRemote
    end
end

return LootDataService