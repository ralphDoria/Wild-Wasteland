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

local MasterList: {[Instance | Tool]: Types_LootSystem.StandardLootableObject} = {}
local onLootDataChangedRemotes: {[Instance | Tool]: RemoteEvent} = {}

function LootDataService.init()
    local connections = handleTaggedInstances(TAGS_LOOT.STANDARD_CONTAINER, 
        function(taggedInstance: Instance)
            local space
            if taggedInstance:HasTag("StorageWearable") then
                space = taggedInstance:GetAttribute("Space")
                if space == nil then
                    error(`{taggedInstance.Name} is missing attribute "Space"`)
                end
            else
                space = 20
            end
            LootDataService.Register(taggedInstance, StandardLootable.new(space))
            onLootDataChangedRemotes[taggedInstance] = Instance.new("RemoteEvent")
            onLootDataChangedRemotes[taggedInstance].Parent = ReplicatedStorage
        end,
        function(taggedInstance: Instance)  
            LootDataService.Deregister(taggedInstance)
        end
    )

    rfn.GetLootData.OnServerInvoke = function(player, lootable: Model | Instance): Types_LootSystem.StandardLootableObject?
        return MasterList[lootable]
    end

    rfn.TrySlotInteraction.OnServerInvoke = function(player, lootable: Instance, changeRequests: {Types_LootSystem.dataChangeRequestPacket})
        local standardLootable = MasterList[lootable]
        if not standardLootable then
            warn(`{lootable} is not registered.`)
            return false
        end
        local changeReplicator = onLootDataChangedRemotes[lootable]
        if changeReplicator then
            local success: boolean = StandardLootable.makeDataChange(player, standardLootable, changeRequests, changeReplicator)
            return success
        else
            warn("Couldn't find corresponding RemoteEvent for lootable")
            return false
        end

    end

    rfn.OverrideItemData.OnServerInvoke = function(player, lootable, itemData: Types_LootSystem.StandardLootableObjectItems)
        MasterList[lootable].items = itemData
        return true
    end

    LootDataService.initialized = true

    rfn.GetChangeReplicatorRemote.OnServerInvoke = function(player, lootable: Instance | Model): RemoteEvent?
        while onLootDataChangedRemotes[lootable] == nil do
            task.wait()
            print(`Waiting for {Instance} to be initialized`)
        end
        return onLootDataChangedRemotes[lootable]
    end
end

function LootDataService.Register(lootable: Instance, lootableObject: Types_LootSystem.StandardLootableObject)    
    if MasterList[lootable] == nil then
        MasterList[lootable] = lootableObject
    else
        warn(`{lootable} is already registered`)
    end
end

function LootDataService.Deregister(lootable: Instance)
    if MasterList[lootable] then
        StandardLootable.Destroy(MasterList[lootable])
        MasterList[lootable] = nil
    end
end

return LootDataService