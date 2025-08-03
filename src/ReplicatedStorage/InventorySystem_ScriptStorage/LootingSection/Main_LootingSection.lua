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

local LootingSection = {}

local function constructCorpseLootData(): Types_LootSystem.CorpseFilledSlotsData
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

    local appendConnections = handleTaggedInstances(TAGS_LOOT.CORPSE_LOOTABLE, 
        function(taggedInstance: Model | Tool) 
            initClientLootable(taggedInstance)
        end,
        function(taggedInstance: Instance)  

        end
    )

    for _, v in appendConnections do
        table.insert(connections, v)
    end

    local function constructCorpserFilledSlotsDataAndDestroyInventory(): Types_LootSystem.CorpseFilledSlotsData
        local corpseFilledSlotsData = {}
        local hotbar = References_Inventory_Client.Hotbar
        local inventory = References_Inventory_Client.InventoryScrollingFrame

        corpseFilledSlotsData["0"] = {
           equipmentTool = nil,
           slotGroupData = {} 
        }:: Types_LootSystem.CorpseFilledSlotsData
        carryBelt_slotGroupData = corpseFilledSlotsData["0"].slotGroupData
        for _, hotbarSlotInstance in hotbar:GetChildren() do
           local hotbarSlotObject = SlotRegistry.instanceToObjectMap[hotbarSlotInstance]
            carryBelt_slotGroupData[tostring(hotbarSlotObject.HotbarNumber)] = hotbarSlotObject.tool 
            Slot.destroy(hotbarSlotObject)
        end

        for equipmentCategory, equipmentSlotObject in SlotRegistry.wearableCategoryToObjectMap do
            local equipmentSlotAndHotbarData = corpseFilledSlotsData[tostring(equipmentSlotObject._itself.LayoutOrder)]
            local equipmentTool = equipmentSlotObject.tool
            equipmentSlotAndHotbarData.equipmentTool = equipmentTool
            local associatedItemGroup: ObjectValue? = equipmentTool:FindFirstChild("AssociatedItemGroup")
            equipmentSlotAndHotbarData.slotGroupData = SlotGroupRegistry[associatedItemGroup.Value]

            Slot.destroy(equipmentSlotObject)
        end
        for _, slotGroupInstance in inventory:GetChildren() do
        
        end
    end

    table.insert(
        connections,
        Players.PlayerAdded:Connect(function(player: Player)  
            local char = player.Character
            if not char then
                
            end
        end)
    )
end

function LootingSection.ResizeGui()
    LootGuiManager.ResizeGui()
end

return LootingSection