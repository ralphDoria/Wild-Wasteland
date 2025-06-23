--!strict
local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local LootingSystem_Storage = References_Inventory_Client.ReplicatedStorage.LootingSystem_Storage
local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)

local Promise = require(RS.Packages.Promise)

local rfn: {[string] : RemoteFunction} = {
    WaitForServersideInit = LootingSystem_Storage.Remotes.WaitForServersideInit,
    GetLootData = LootingSystem_Storage.Remotes.GetLootData,
    RequestDataChange = LootingSystem_Storage.Remotes.RequestDataChange
}

local LootActions = {}

--[[
    Yields when called, waiting for LootDataService to be initialized.
]]
function LootActions.init()
    rfn.WaitForServersideInit:InvokeServer() -- yields until serverside initializes
end

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

-- function LootActions.RequestDataChange(lootable: Model | Tool, ): boolean
--     return rfn.RequestDataChange:InvokeServer(lootable, )
-- end

return LootActions