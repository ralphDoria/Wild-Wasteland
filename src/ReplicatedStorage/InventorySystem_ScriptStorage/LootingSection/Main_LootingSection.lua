local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local lootingSectionComponents = InventoryScriptStorage.LootingSection.Components
local LootGuiManager = require(lootingSectionComponents.LootGuiManager)
local Types_LootSystem = require(lootingSectionComponents.Types_LootSystem)
local ScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local SlotRegistry = require(ScriptStorage.Components.Slot.SlotRegistry)
local SlotGroupRegistry = require(ScriptStorage.Components.Slot.SlotGroupRegistry)
local Slot = require(ScriptStorage.Components.Slot.Slot)
local SlotGroup = require(ScriptStorage.Components.Slot.SlotGroup)
local remotes: {[string]: RemoteEvent} = {
    SendClientCorpseFilledSlotsData = References_Inventory_Client.LootingRemotes.SendClientCorpseFilledSlotsData:: RemoteEvent,
    moveToolsToLootItemsHolding = References_Inventory_Client.LootingRemotes.MoveToolsToLootItemsHolding:: RemoteEvent,
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


local function constructCorpseFilledSlotsDataAndDestroyInventoryData(): Types_LootSystem.CorpseFilledSlotsData
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
            carryBelt_slotGroupData[hotbarSlotObject.HotbarNumber.Text] = if hotbarSlotObject.tool and hotbarSlotObject.tool.Parent == References_Inventory_Client.character then nil else hotbarSlotObject.tool
            Slot.destroy(hotbarSlotObject)
        else
            -- warn(`{hotbarSlotInstance} is not registered in slot registry`)
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

local function sendCorpseFilledSlotsData(character: Model)
    local hrp = character:WaitForChild("HumanoidRootPart")
    local filledSlotsData = constructCorpseFilledSlotsDataAndDestroyInventoryData()
    -- print(filledSlotsData)
    remotes.moveToolsToLootItemsHolding:FireServer(character)
    remotes.SendClientCorpseFilledSlotsData:FireServer(filledSlotsData, hrp)
end

function LootingSection.init()
    LootGuiManager.init()

    -- send corpsefilleslots data when player dies and server will initialize a corpse lootable
    local humanoid: Humanoid = References_Inventory_Client.character:WaitForChild("Humanoid"):: Humanoid
    humanoid.Died:Once(function()  
        sendCorpseFilledSlotsData(References_Inventory_Client.character)
    end)
end

function LootingSection.ResizeGui()
    LootGuiManager.ResizeGui()
end

return LootingSection