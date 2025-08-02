--!strict
local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local UIS = References_Inventory_Client.UserInputService

local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local SlotGroup = require(InventoryScriptStorage.Components.Slot.SlotGroup)
local Slot = require(InventoryScriptStorage.Components.Slot.Slot)
local Types_LootSystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)
local EquipmentInitData = require(InventoryScriptStorage.CharacterSection.Components.EquipmentInitData)
local ToggleOVerrideCamModeCursorLock = require(InventoryScriptStorage.Components.Misc.ToggleOverrideCamModeCursorLock)

local LootGuiManager = {}

local renderChangedBindable: BindableEvent = Instance.new("BindableEvent")
LootGuiManager.renderChanged = renderChangedBindable.Event

type EquipmentSlotsTbl = {number: Slot.SlotObject}
type SlotGroupObjectsTbl = {number: SlotGroup.object}

type CorpseRenderType = {
    equipmentSlots: EquipmentSlotsTbl,
    slotGroupObjects: SlotGroupObjectsTbl
}

local type_currentlyRendering: ("Standard" | "Corpse")? = nil
LootGuiManager.currentlyRendering = nil :: any

function LootGuiManager.init()
    
    --need to initialize corpse equipment slots first
    LootGuiManager.ResizeGui()
end

function LootGuiManager.ResizeGui()
    local equipmentSlotsWidth = References_Inventory_Client.LootingEquipmentSlots.AbsoluteSize.X
    local lootingSectionWidth = References_Inventory_Client.LootingSection.AbsoluteSize.X
    
    References_Inventory_Client.LootingScrollingFrame.Size = UDim2.new(0, lootingSectionWidth - equipmentSlotsWidth, 1, 0)
end

local function initLootingEquipmentSlots(): EquipmentSlotsTbl
    local lootingEquipmentSlots = {}:: EquipmentSlotsTbl
    for key, v in EquipmentInitData do
        local slot: Slot.SlotObject
        slot = Slot.new("Wearable")
        slot._itself.AnchorPoint = Vector2.new(0.5, 0.5)
        slot._itself.ZIndex = 2
        slot._itself.LayoutOrder = v.LayoutOrder
        slot.ImageButton.Image = v.image
        slot.ImageButton.Rotation = 0
        slot.ImageButton.Visible = true
        slot._itself.Name = key
        slot._itself.Parent = References_Inventory_Client.LootingEquipmentSlots
        lootingEquipmentSlots[v.LayoutOrder] = slot 
    end
    return lootingEquipmentSlots
end

function LootGuiManager.RenderData(lootable: Model | Tool, filledSlotsData: any)
    LootGuiManager.StopRendering()

    References_Inventory_Client.LootableInstanceObjectValue.Value = lootable
    References_Inventory_Client.LootingSectionTitle.Text = lootable.Name

    if filledSlotsData["1"] then
        local filledSlotsData = filledSlotsData:: Types_LootSystem.CorpseFilledSlotsData
        local lootingEquipmentSlots = initLootingEquipmentSlots()
        local currentlyRendering: CorpseRenderType = {
            equipmentSlots = lootingEquipmentSlots,
            slotGroupObjects = {}:: SlotGroupObjectsTbl -- table will be populated in the loop below
        }
        for string_equipmentSlotNumber: string, equipmentToolAndSlotGroupData in filledSlotsData do
            local equipmentSlotName: string? = Types_LootSystem.getEquipmentSlotName(tonumber(string_equipmentSlotNumber):: number)
            local lootingEquipmentSlot: Slot.SlotObject? = if equipmentSlotName then lootingEquipmentSlots[equipmentSlotName] else nil

            if lootingEquipmentSlot then
                local equipmentTool: Tool? = equipmentToolAndSlotGroupData.equipmentTool
                if equipmentTool then -- If an equipmentTool exists, then the lootingEquipmentSlot is supposed to be filled
                    Slot.FillSlot(lootingEquipmentSlot, equipmentTool)

                    local slotGroupData = equipmentToolAndSlotGroupData.slotGroupData
                    local slotGroupObject = SlotGroup.new(equipmentSlotName:: string, lootable:GetAttribute("Space"):: number, slotGroupData, References_Inventory_Client.LootingScrollingFrame)
                    slotGroupObject._itself.LayoutOrder = tonumber(string_equipmentSlotNumber):: number
                    currentlyRendering.slotGroupObjects[tonumber(string_equipmentSlotNumber):: number] = slotGroupObject
                end
            else
                warn(`{string_equipmentSlotNumber} is not a valid equipment slot number`)
            end
        end

        type_currentlyRendering = "Corpse"
        LootGuiManager.currentlyRendering = currentlyRendering
    else
        local filledSlotsData = filledSlotsData:: Types_LootSystem.StandardFilledSlotsData
        local slotGroup = SlotGroup.new("", lootable:GetAttribute("Space"):: number, filledSlotsData, References_Inventory_Client.LootingScrollingFrame)
        
        type_currentlyRendering = "Standard"
        LootGuiManager.currentlyRendering = slotGroup
    end
    renderChangedBindable:Fire(lootable)
end

local function overrideSlotInSlotGroup(slotGroupObject: SlotGroup.object, layoutOrder: number, substituteTool: Tool?)
    for _, v in slotGroupObject.SlotsFrame:GetChildren() do
        if v:IsA("Frame") and v.LayoutOrder == layoutOrder then
            local lootSlot = Slot.new("Inventory") 
            lootSlot._itself.LayoutOrder = v.LayoutOrder
            if substituteTool then
                Slot.FillSlot(lootSlot, substituteTool)
            end
            lootSlot._itself.Parent = v.Parent
            v:Destroy()
            break
        end
    end
end

function LootGuiManager.replaceSlot(dataChangeRequest: any)
    if LootGuiManager.currentlyRendering == nil then
        warn("Can't replace slot in gui: Nothing is currently being rendered by LootGuiManager")
        return
    end

    if dataChangeRequest.__type == Types_LootSystem.EnumLootableTypes.Standard then
        local dataChangeRequest = dataChangeRequest:: Types_LootSystem.StandardDataChangeRequest
        local currentlyRendering: SlotGroup.object = LootGuiManager.currentlyRendering

        local lootToolLayoutOrder = dataChangeRequest.lootToolLayoutOrder
        local toolReplacement = dataChangeRequest.substituteTool
        
        overrideSlotInSlotGroup(currentlyRendering, lootToolLayoutOrder, toolReplacement)
    elseif dataChangeRequest.__type == Types_LootSystem.EnumLootableTypes.Corpse then
        local dataChangeRequest = dataChangeRequest:: Types_LootSystem.CorpseDataChangeRequest
        local currentlyRendering: CorpseRenderType = LootGuiManager.currentlyRendering

        local lootToolLayoutOrder = dataChangeRequest.lootToolLayoutOrder
        local toolReplacement = dataChangeRequest.substituteTool
        local equipmentToolLayoutOrder = dataChangeRequest.equipmentToolLayoutOrder

        if lootToolLayoutOrder == nil then
            -- Equipment slot is to be replaced with substitute tool
            SlotGroup.Destroy(currentlyRendering.slotGroupObjects[equipmentToolLayoutOrder])
            currentlyRendering.slotGroupObjects[equipmentToolLayoutOrder] = nil
            local equipmentSlot = Slot.instanceToObjectMap[currentlyRendering.equipmentSlots[equipmentToolLayoutOrder]] 
            Slot.EmptySlot(equipmentSlot)
            if toolReplacement then
                Slot.FillSlot(equipmentSlot, toolReplacement)
            end
        else
            -- Slot in specified layout order within specified equipment number's slot group is to be replaced
            overrideSlotInSlotGroup(currentlyRendering.slotGroupObjects[equipmentToolLayoutOrder], lootToolLayoutOrder, toolReplacement)    
        end
    end
end

function LootGuiManager.StopRendering()
    if References_Inventory_Client.LootableInstanceObjectValue.Value and LootGuiManager.currentlyRendering then
        if type_currentlyRendering == "Standard" then
            local currentlyRendering = LootGuiManager.currentlyRendering:: CorpseRenderType
            for _, lootEquipmentSlot in currentlyRendering.equipmentSlots do
                Slot.destroy(lootEquipmentSlot:: Slot.SlotObject) 
            end
            for _, slotGroupObject in currentlyRendering.slotGroupObjects do
                SlotGroup.Destroy(slotGroupObject:: SlotGroup.object)
            end
        elseif type_currentlyRendering == "Corpse" then
            local currentlyRendering = LootGuiManager.currentlyRendering:: SlotGroup.object
            SlotGroup.Destroy(currentlyRendering)
        else
            warn("Can't stop rendering because type_currentlyRendering is neither Standard nor Corpse, implying that nothing is being rendered")
        end
        LootGuiManager.currentlyRendering = nil
        References_Inventory_Client.LootableInstanceObjectValue.Value = nil
        renderChangedBindable:Fire(nil)
    end
end

function LootGuiManager.toggle(toggle: boolean, externalStoreName: string?)
    if References_Inventory_Client.LootingSection.Visible == toggle then return end
    ToggleOVerrideCamModeCursorLock(toggle)
end

return LootGuiManager