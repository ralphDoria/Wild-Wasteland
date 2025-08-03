local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local handleTaggedInstances = require(RS.RojoManaged_RS.Utility.handleTaggedInstances)
local TAGS_LOOT = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.TAGS_LOOT)

local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local lootingSectionComponents = InventoryScriptStorage.LootingSection.Components
local LootGuiManager = require(lootingSectionComponents.LootGuiManager)
local initClientLootable = require(lootingSectionComponents.initClientLootable)
local Types_LootSystem = require(lootingSectionComponents.Types_LootSystem)
local ScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local SlotRegistry = require(ScriptStorage.Components.Slot.SlotRegistry)
local SlotGroupRegistry = require(ScriptStorage.Components.Slot.SlotGroupRegistry)
local Slot = require(ScriptStorage.Components.Slot.Slot)
local SlotGroup = require(ScriptStorage.Components.Slot.SlotGroup)
local remotes: {[string]: RemoteEvent} = {
    SendClientCorpseFilledSlotsData = References_Inventory_Client.LootingRemotes.SendClientCorpseFilledSlotsData:: RemoteEvent
}

local LootingSection = {}

local function constructEmptyCorpseLootData(): Types_LootSystem.CorpseFilledSlotsData
    local filledSlotsData = {}
    for _, equipmentSlotNumber in Types_LootSystem.EnumEquipmentSlots do

        filledSlotsData[tostring(equipmentSlotNumber)] = {
            equipmentTool = nil,
            slotGroupData = {}
        } 
    end
    return filledSlotsData
end

function LootingSection.init()

    LootGuiManager.init()

    local connections = handleTaggedInstances(TAGS_LOOT.STANDARD_LOOTABLE, 
        function(taggedInstance: Model | Tool) 
            if taggedInstance:HasTag("StorageWearable") then
                -- will be initialized within StorageWearable's code
                return
            end
            initClientLootable(taggedInstance)
        end,
        function(taggedInstance: Instance)  

        end
    )

    local function constructCorpseFilledSlotsDataAndDestroyInventory(): Types_LootSystem.CorpseFilledSlotsData
        local corpseFilledSlotsData = constructEmptyCorpseLootData()
        local hotbar = References_Inventory_Client.Hotbar

        corpseFilledSlotsData["0"] = {
           equipmentTool = nil,
           slotGroupData = {} 
        }:: Types_LootSystem.CorpseFilledSlotsData
        local carryBelt_slotGroupData = corpseFilledSlotsData["0"].slotGroupData
        for _, hotbarSlotInstance in hotbar:GetChildren() do
            local hotbarSlotObject = SlotRegistry.instanceToObjectMap[hotbarSlotInstance]
            if hotbarSlotObject then
                carryBelt_slotGroupData[hotbarSlotObject.HotbarNumber.Text] = hotbarSlotObject.tool 
                Slot.destroy(hotbarSlotObject)
            else
                warn(`{hotbarSlotInstance} is not registered in slot registry`)
            end
        end

        for equipmentCategory, equipmentSlotObject in SlotRegistry.wearableCategoryToObjectMap do
            local equipmentSlotAndHotbarData = corpseFilledSlotsData[tostring(equipmentSlotObject._itself.LayoutOrder)]
            local equipmentTool = equipmentSlotObject.tool
            equipmentSlotAndHotbarData.equipmentTool = equipmentTool
            local associatedItemGroup: ObjectValue? = if equipmentTool then equipmentTool:FindFirstChild("AssociatedItemGroup") else nil
            if associatedItemGroup then
                local slotGroupObject = SlotGroupRegistry.instanceToObjectMap[associatedItemGroup.Value]
                print(associatedItemGroup.Value, slotGroupObject)
                if slotGroupObject then
                    local slotGroupData = {}
                    for _, slotObject in slotGroupObject.slotInstanceToObjectMap do
                    slotGroupData[tostring(slotObject._itself.LayoutOrder)] = slotObject.tool 
                    end
                    print(slotGroupData)
                    equipmentSlotAndHotbarData.slotGroupData = slotGroupData
                    
                    SlotGroup.Destroy(slotGroupObject)
                else
                    warn(`{associatedItemGroup.Value} is not mapped to a slotGroupObject in slot group registry`)
                end
            end

            Slot.destroy(equipmentSlotObject)
        end

       return corpseFilledSlotsData 
    end

    local function sendCorpseFilledSlotsData(character)
        local hrp = character:WaitForChild("HumanoidRootPart")
        while not hrp:HasTag(TAGS_LOOT.CORPSE_LOOTABLE) do
            warn("Waiting for server to tag hrp w/ corpse lootable tag, signifying that event receiver is connected")
            task.wait()
        end
        local filledSlotsData = constructCorpseFilledSlotsDataAndDestroyInventory()
        print(filledSlotsData)
        remotes.SendClientCorpseFilledSlotsData:FireServer(filledSlotsData)
    end

    local appendConnections = handleTaggedInstances(
        TAGS_LOOT.CORPSE_LOOTABLE, 
        function(taggedInstance: Instance)  
            -- taggedInstance should be the HumanoidRootPart of the character model, regardless of if it's a player or NPC
            local character = taggedInstance.Parent:: Model
            sendCorpseFilledSlotsData(character)
            initClientLootable(taggedInstance:: Model)
        end, 
        function(taggedInstance: Instance)  
        end
    )

    for _, v in appendConnections do
        table.insert(connections, v)
    end
end

function LootingSection.ResizeGui()
    LootGuiManager.ResizeGui()
end

return LootingSection