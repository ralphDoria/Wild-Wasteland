--!strict
local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local LootingSystem_Storage = References_Inventory_Client.ReplicatedStorage.LootingSystem_Storage
local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)

local Promise = require(RS.Packages.Promise)

local rfn: {[string] : RemoteFunction} = {
    GetLootData = LootingSystem_Storage.Remotes.GetLootData,
    TrySlotInteraction = LootingSystem_Storage.Remotes.TrySlotInteraction
}

local LootActions = {}

--[[
    Yields when called, waiting for LootDataService to be initialized.
]]

function LootActions.GetData(lootable: Model | Tool)
    return Promise.new(function(resolve, reject, onCancel)
        local lootData: Types_LootSystem.StandardLootableObject? = rfn.GetLootData:InvokeServer(lootable)
        
        onCancel(function()
            
        end)

        if lootData then
            resolve(lootData)
        else
            reject(`{lootable} is not registered on the server`)
        end
    end)
end

type dataToSwap = {

}

function LootActions.TrySlotInteraction(lootable: Model | Tool, dataChangeRequestPacket: Types_LootSystem.dataChangeRequestPacket)
    return Promise.new(function(resolve, reject)
        local success: boolean = rfn.TrySlotInteraction:InvokeServer(lootable, dataChangeRequestPacket)

        if success then
            resolve(dataChangeRequestPacket.syncCheck)
        else
            reject("Something went wrong")
        end
    end)
end

return LootActions