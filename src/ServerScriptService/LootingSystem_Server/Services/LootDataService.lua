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
    WaitForServersideInit = LootingSystem_Storage.Remotes.WaitForServersideInit,
    GetLootData = LootingSystem_Storage.Remotes.GetLootData,
    RequestDataChange = LootingSystem_Storage.Remotes.RequestDataChange
}

local LootDataService = {
    initialized = false
}

local MasterList: {[Instance | Tool]: Types_LootSystem.StandardLootableObject} = {}

function LootDataService.init()
    local connections = handleTaggedInstances(TAGS_LOOT.STANDARD_CONTAINER, 
        function(taggedInstance: Instance)  
            LootDataService.Register(taggedInstance, StandardLootable.new(20))
        end,
        function(taggedInstance: Instance)  
            LootDataService.Deregister(taggedInstance)
        end
    )

    rfn.GetLootData.OnServerInvoke = function(player, lootable: Model | Instance): Types_LootSystem.StandardLootableObject?
        return MasterList[lootable]
    end

    -- rfn.RequestDataChange.OnServerInvoke =

    LootDataService.initialized = true

    rfn.WaitForServersideInit.OnServerInvoke = function(player)
        while LootDataService.initialized == false do
            task.wait(1)
        end
        return true
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