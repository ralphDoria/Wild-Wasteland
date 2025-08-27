local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)
local References_ActionHandlers = require(script.Parent.References_ActionHandlers)

local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local Type_Equipment = require(InventoryScriptStorage.CharacterSection.Components.Type_Equipment)
local Types_Slot = require(InventoryScriptStorage.Components.Slot.Type_Slot)

local Utility = {}

-- helper function for displaying a loading effect over slot
function Utility.loadSlot(slot: Types_Slot.SlotObject, duration: number)
    local progressBar = Instance.new("Frame")
    progressBar.Transparency = 0.5
    progressBar.Size = UDim2.fromScale(1, 1)
    progressBar.Parent = slot._itself
    local tween = References_ActionHandlers.TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)})
    tween.Completed:Connect(function()  
        progressBar:Destroy()
    end)
    return tween
end

function Utility.isRelatedViaSlotGroup(wearableSlotData: types_and_enums.SlotData, otherSlot: types_and_enums.SlotData): boolean
    if wearableSlotData.slotGroupInstance and wearableSlotData.slotGroupInstance == otherSlot.slotGroupInstance then 
        print("checkpoint 1")
        References_ActionHandlers.DiegeticErrorMessagingManager.AddMessage("Logically, that's not possible")
        return true
    else
        return false    
    end
end


function Utility.getEquipmentSlotObjectFromLayoutOrder(layoutOrder: number)
    if layoutOrder == 0 then return nil end

    local equipmentSlotInstance = References_Inventory.LootingEquipmentSlots[Type_Equipment.validWearableCategories[layoutOrder]]
    local equipmentSlotObject = References_ActionHandlers.SlotRegistry.instanceToObjectMap[equipmentSlotInstance]
    return equipmentSlotObject
end

function Utility.getLootInventorySlotEquipmentToolInfo(lootInventorySlot: Types_Slot.SlotObject): (number?, Tool?)
    if #References_Inventory.LootingEquipmentSlots:GetChildren() < 2 then return end
    local slotsFrame = lootInventorySlot._itself.Parent
    local slotGroupInstance = slotsFrame.Parent
    local layoutOrder = slotGroupInstance.LayoutOrder

    local equipmentSlotObject = Utility.getEquipmentSlotObjectFromLayoutOrder(layoutOrder)

    return layoutOrder, if equipmentSlotObject then equipmentSlotObject.tool else nil
end

return Utility