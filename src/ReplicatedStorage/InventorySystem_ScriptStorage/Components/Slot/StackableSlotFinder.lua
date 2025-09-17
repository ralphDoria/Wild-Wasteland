
local RS = game:GetService("ReplicatedStorage")
local ScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
-- local HotbarSection = require(ScriptStorage.HotbarSection.Main_HotbarSection)
-- local InventorySection = require(ScriptStorage.InventorySection.Main_InventorySection)
local Type_Slot = require(ScriptStorage.Components.Slot.Type_Slot)
local SlotGroupRegistry = require(ScriptStorage.Components.Slot.SlotGroupRegistry)
local HotbarSlotsRegistry = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.HotbarSection.Components.HotbarSlotsRegistry)
local References_Inventory = require(ScriptStorage.Components.References_Inventory_Client)

local StackableSlotFinder = {}

local function isUnmaxedStackable(slot: Type_Slot.SlotObject)
    assert(slot.tool)
    local currentQuantity = slot.tool:GetAttribute("Quantity")
    local MAX_QUANTITY = slot.tool:GetAttribute("MAX_QUANTITY")
    if currentQuantity and MAX_QUANTITY and currentQuantity ~= MAX_QUANTITY then
        return true
    else
        return false
    end
end
function StackableSlotFinder.hotbar(stackableName: string): Type_Slot.SlotObject?
    local currentSlot: Type_Slot.SlotObject? = nil

    for _, v in HotbarSlotsRegistry.instanceToObjectMap do
        if v.tool and v.tool.Name == stackableName then
            if isUnmaxedStackable(v) then
                if not currentSlot then
                    currentSlot = v
                else
                    if currentSlot._itself.LayoutOrder > v._itself.LayoutOrder then
                        currentSlot = v
                    end
                end
            end
        end
    end

    return currentSlot
end

function StackableSlotFinder.inventory(stackableName: string): Type_Slot.SlotObject?
	local currentSlot: Type_Slot.SlotObject?

    for _, slotGroupObject in SlotGroupRegistry.instanceToObjectMap do
        if slotGroupObject._itself:FindFirstAncestor(References_Inventory.LootingScrollingFrame.Name) then return end
        for instance, object in slotGroupObject.slotInstanceToObjectMap do
            if object.tool and object.tool.Name == stackableName then
                if isUnmaxedStackable(object) then
                    if not currentSlot then
                        currentSlot = object
                    else
                        if currentSlot._itself.LayoutOrder > object._itself.LayoutOrder then
                            currentSlot = object
                        end
                    end
                end
            end
        end
    end

    return currentSlot
end

function StackableSlotFinder.getSum(stackableName: string): number
    local sum = 0
    local function addStackableQuantityToSum(tool: Tool)
            local quantity = tool:GetAttribute("Quantity")
            if typeof(quantity) == "number" then
                sum += quantity
            end
    end
    for _, v in HotbarSlotsRegistry.instanceToObjectMap do
        if v.tool and v.tool.Name == stackableName then
            print("found stackable to add its quantity to sum")
            addStackableQuantityToSum(v.tool)
        end
    end
    for _, slotGroupObject in SlotGroupRegistry.instanceToObjectMap do
        if slotGroupObject._itself:FindFirstAncestor(References_Inventory.LootingScrollingFrame.Name) then continue end

        for instance, object in slotGroupObject.slotInstanceToObjectMap do
            if object.tool and object.tool.Name == stackableName then
                addStackableQuantityToSum(object.tool)
            end
        end
    end

    return sum
end

function StackableSlotFinder.any(stackableName: string): Type_Slot.SlotObject?
	local slotObject: Type_Slot.SlotObject?
	slotObject = StackableSlotFinder.hotbar(stackableName)
	if not slotObject then
		slotObject = StackableSlotFinder.inventory(stackableName)
	end
	return slotObject
end

return StackableSlotFinder