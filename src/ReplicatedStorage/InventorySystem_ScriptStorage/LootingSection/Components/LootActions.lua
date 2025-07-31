--!strict
local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local LootingSystem_Storage = References_Inventory_Client.ReplicatedStorage.LootingSystem_Storage
local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)
local Type_SlotGroup = require(InventoryScriptStorage.Components.Slot.Type_SlotGroup)

local Promise = require(RS.Packages.Promise)

local rfn: {[string] : RemoteFunction} = {
    GetLootData = LootingSystem_Storage.Remotes.GetLootData,
    TrySlotInteraction = LootingSystem_Storage.Remotes.TrySlotInteraction,
    OverrideItemData = LootingSystem_Storage.Remotes.OverrideItemData
}

local LootActions = {}

--[[
    Yields when called, waiting for LootDataService to be initialized.
]]

function LootActions.GetData(lootable: Model | Tool)
    return Promise.new(function(resolve, reject, onCancel)
        local filledSlotsData: Types_LootSystem.StandardFilledSlotsData = rfn.GetLootData:InvokeServer(lootable)
        -- warn("received filledSlots from client")
        -- warn(filledSlotsData)
        
        onCancel(function()
            
        end)

        if filledSlotsData then
            resolve(filledSlotsData)
        else
            reject(`{lootable} is not registered on the server`)
        end
    end)
end


local function convertToFilledSlotsData(slotGroup: Type_SlotGroup.object): Types_LootSystem.StandardFilledSlotsData
    local filledSlotsData: Types_LootSystem.StandardFilledSlotsData = {}
    local slotInstanceToObjectMap = slotGroup.slotInstanceToObjectMap
    for _, v in slotGroup.SlotsFrame:GetChildren() do
        if v:IsA("Frame") then
            filledSlotsData[tostring(v.LayoutOrder)] = slotInstanceToObjectMap[v].tool
        end
    end 
    return filledSlotsData
end

function LootActions.updateStorageWearableLootData(tool: Tool, slotGroup: Type_SlotGroup.object)
    local filledSlotsData = convertToFilledSlotsData(slotGroup)
    return Promise.new(function(resolve, reject)
        local success: boolean = rfn.OverrideItemData:InvokeServer(tool, filledSlotsData)

        if success then
            resolve()
        else
            reject("Something went wrong")
        end
    end)
end



function LootActions.TrySlotInteraction(lootable: Model | Tool, ...: Types_LootSystem.StandardDataChangeRequestPacket)
    local changeRequests = {...}
    return Promise.new(function(resolve, reject)
        local success: boolean = rfn.TrySlotInteraction:InvokeServer(lootable, changeRequests)

        if success then
            resolve()
        else
            reject("Something went wrong")
        end
    end)
end

return LootActions