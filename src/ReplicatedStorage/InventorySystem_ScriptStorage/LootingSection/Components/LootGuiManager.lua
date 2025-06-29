--!strict
local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local UIS = References_Inventory_Client.UserInputService

local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local SlotGroup = require(InventoryScriptStorage.Components.Slot.SlotGroup)
local Slot = require(InventoryScriptStorage.Components.Slot.Slot)
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local ToggleOVerrideCamModeCursorLock = require(InventoryScriptStorage.Components.Misc.ToggleOverrideCamModeCursorLock)

local LootGuiManager = {}

local renderChangedBindable: BindableEvent = Instance.new("BindableEvent")
LootGuiManager.renderChanged = renderChangedBindable.Event

LootGuiManager.currentlyRendering = nil:: SlotGroup.object?

function LootGuiManager.init()
    
    --need to initialize corpse equipment slots first
    LootGuiManager.ResizeGui()
end

function LootGuiManager.ResizeGui()
    local equipmentSlotsWidth = References_Inventory_Client.LootingEquipmentSlots.AbsoluteSize.X
    local lootingSectionWidth = References_Inventory_Client.LootingSection.AbsoluteSize.X
    
    References_Inventory_Client.LootingScrollingFrame.Size = UDim2.new(0, lootingSectionWidth - equipmentSlotsWidth, 1, 0)
end

function LootGuiManager.RenderData(lootable: Model | Tool, filledSlotsData: Types_LootSystem.FilledSlotsData)
    LootGuiManager.StopRendering()

    References_Inventory_Client.LootableInstanceObjectValue.Value = lootable
    References_Inventory_Client.LootingSectionTitle.Text = lootable.Name
    local slotGroup = SlotGroup.new("", lootable:GetAttribute("Space"):: number, filledSlotsData, References_Inventory_Client.LootingScrollingFrame)
    
    LootGuiManager.currentlyRendering = slotGroup
    renderChangedBindable:Fire(slotGroup._itself)
end

function LootGuiManager.replaceSlot(layoutOrder: number, toolReplacement: Tool?)
    if LootGuiManager.currentlyRendering == nil then
        warn("Slot group is nil")
        return
    end

    for _, v in LootGuiManager.currentlyRendering.SlotsFrame:GetChildren() do
        if v:IsA("Frame") and v.LayoutOrder == layoutOrder then
            local lootSlot = Slot.new("Inventory") 
            lootSlot._itself.LayoutOrder = v.LayoutOrder
            if toolReplacement then
                Slot.FillSlot(lootSlot, toolReplacement)
            end
            lootSlot._itself.Parent = v.Parent
            v:Destroy()
            break
        end
    end
end

function LootGuiManager.StopRendering()
    if References_Inventory_Client.LootableInstanceObjectValue.Value and LootGuiManager.currentlyRendering then
        SlotGroup.Destroy(LootGuiManager.currentlyRendering)
        LootGuiManager.currentlyRendering = nil
        renderChangedBindable:Fire(nil)

        References_Inventory_Client.LootableInstanceObjectValue.Value = nil
    end
end

function LootGuiManager.toggle(toggle: boolean, externalStoreName: string?)
    if References_Inventory_Client.LootingSection.Visible == toggle then return end
    ToggleOVerrideCamModeCursorLock(toggle)
end

return LootGuiManager