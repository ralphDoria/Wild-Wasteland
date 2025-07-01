local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local Type_Slot = require(InventoryScriptStorage.Components.Slot.Type_Slot)
local SlotGroup = require(InventoryScriptStorage.Components.Slot.SlotGroup)

local InventorySection = {}

function InventorySection.findFirstEmptySlot(): Type_Slot.SlotObject?
    local slotObjectToReturn: Type_Slot.SlotObject?

    local lowestLayoutOrder: number = math.huge
    for _, slotGroupObject in SlotGroup.createdObjects do
        for instance, object in slotGroupObject.slotInstanceToObjectMap do
            if object._isEmpty then
                local layoutOrder = instance.LayoutOrder 
                if layoutOrder < lowestLayoutOrder then
                    lowestLayoutOrder = layoutOrder
                    slotObjectToReturn = object
                end
            end
        end
        if slotObjectToReturn then
            return slotObjectToReturn
        end
    end

    return nil
end

return InventorySection