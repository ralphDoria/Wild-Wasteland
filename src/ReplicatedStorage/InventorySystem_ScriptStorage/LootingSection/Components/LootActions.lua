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


local function serializeSlotGroup(slotGroup: Type_SlotGroup.object): Types_LootSystem.StandardLootableObjectItems
    local itemData: Types_LootSystem.StandardLootableObjectItems = {}
    local itemSlots = slotGroup.ItemSlots
    for _, v in slotGroup.ItemsFrame:GetChildren() do
        if v:IsA("Frame") then
            itemData[v.LayoutOrder] = {
                isGrabbed = false,
                tool = itemSlots[v].tool
            }
        end
    end
    return itemData
end

function LootActions.updateStorageWearableLootData(tool: Tool, slotGroup: Type_SlotGroup.object)
    local itemData = serializeSlotGroup(slotGroup)

    return Promise.new(function(resolve, reject)
        local success: boolean = rfn.OverrideItemData:InvokeServer(tool, itemData)

        if success then
            resolve()
        else
            reject("Something went wrong")
        end
    end)
end



function LootActions.TrySlotInteraction(lootable: Model | Tool, ...: Types_LootSystem.dataChangeRequestPacket)
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