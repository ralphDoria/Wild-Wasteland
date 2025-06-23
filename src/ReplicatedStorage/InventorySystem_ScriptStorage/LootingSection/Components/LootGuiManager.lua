--!strict
local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local UIS = References_Inventory_Client.UserInputService

local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local SlotGroup = require(InventoryScriptStorage.Components.Slot.SlotGroup)
local Slot = require(InventoryScriptStorage.Components.Slot.Slot)
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local ToggleOVerrideCamModeCursorLock = require(InventoryScriptStorage.Components.Misc.ToggleOverrideCamModeCursorLock)

local currentlyRendering: {lootableInstance: (Model | Tool)?, SlotGroup: (SlotGroup.ItemGroupObject)?} = {
    lootableInstance = nil,
    SlotGroup = nil
}

local LootGuiManager = {}

function LootGuiManager.init()
    
    --need to initialize corpse equipment slots first
    LootGuiManager.ResizeGui()
end

function LootGuiManager.ResizeGui()
    local equipmentSlotsWidth = References_Inventory_Client.LootingEquipmentSlots.AbsoluteSize.X
    local lootingSectionWidth = References_Inventory_Client.LootingSection.AbsoluteSize.X
    
    References_Inventory_Client.LootingScrollingFrame.Size = UDim2.new(0, lootingSectionWidth - equipmentSlotsWidth, 1, 0)
end

function LootGuiManager.RenderData(lootable: Model | Tool, lootData: Types_LootSystem.StandardLootableObject)
    LootGuiManager.StopRendering()

    currentlyRendering.lootableInstance = lootable
    References_Inventory_Client.LootingSectionTitle.Text = lootable.Name
    local slotGroup = SlotGroup.new("", lootData.Space)
    slotGroup._itself.Parent = References_Inventory_Client.LootingScrollingFrame
    currentlyRendering.SlotGroup = slotGroup
end

function LootGuiManager.StopRendering()
    if currentlyRendering.lootableInstance and currentlyRendering.SlotGroup then
        SlotGroup.Destroy(currentlyRendering.SlotGroup)
        currentlyRendering.SlotGroup = nil

        currentlyRendering.lootableInstance = nil
    end
end

function LootGuiManager.toggle(toggle: boolean, externalStoreName: string?)
    if References_Inventory_Client.LootingSection.Visible == toggle then return end
    ToggleOVerrideCamModeCursorLock(toggle)
end

return LootGuiManager