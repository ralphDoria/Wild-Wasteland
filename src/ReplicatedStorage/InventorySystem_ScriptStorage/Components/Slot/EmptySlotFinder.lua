local RS = game:GetService("ReplicatedStorage")
local ScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
-- local HotbarSection = require(ScriptStorage.HotbarSection.Main_HotbarSection)
-- local InventorySection = require(ScriptStorage.InventorySection.Main_InventorySection)
local Type_Slot = require(ScriptStorage.Components.Slot.Type_Slot)
local SlotGroupRegistry = require(ScriptStorage.Components.Slot.SlotGroupRegistry)
local HotbarSlotsRegistry = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.HotbarSection.Components.HotbarSlotsRegistry)

local EmptySlotFinder = {}

function EmptySlotFinder.hotbar(): Type_Slot.SlotObject?
	local lowest: Type_Slot.SlotObject? = nil
    for _, v in HotbarSlotsRegistry.instanceToObjectMap do
        if v._isEmpty == true and v.State ~= "BeingSwapped" then
            if lowest == nil then
                lowest = v
            else
                if v._itself.LayoutOrder < lowest._itself.LayoutOrder then
                    lowest = v
                end
            end
        end
    end

    return lowest
end

function EmptySlotFinder.inventory(): Type_Slot.SlotObject?
	local slotObjectToReturn: Type_Slot.SlotObject?

    local lowestLayoutOrder: number = math.huge
    for _, slotGroupObject in SlotGroupRegistry.instanceToObjectMap do
        for instance, object in slotGroupObject.slotInstanceToObjectMap do
            if object._isEmpty and object.State ~= "BeingSwapped" then
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

function EmptySlotFinder.any(): Type_Slot.SlotObject?
	local slotObject: Type_Slot.SlotObject?
	slotObject = EmptySlotFinder.hotbar()
	if not slotObject then
		slotObject = EmptySlotFinder.inventory()
	end
	return slotObject
end

return EmptySlotFinder