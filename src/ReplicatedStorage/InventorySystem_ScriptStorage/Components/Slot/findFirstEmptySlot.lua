local RS = game:GetService("ReplicatedStorage")
local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local HotbarSection = require(ScriptStorage.HotbarSection.Main_HotbarSection)
local InventorySection = require(ScriptStorage.InventorySection.Main_InventorySection)
local Type_Slot = require(ScriptStorage.Components.Slot.Type_Slot)

local function findFirstEmptySlot(): Type_Slot.SlotObject?
	local slotObject: Type_Slot.SlotObject?
	slotObject = HotbarSection.findFirstEmptySlot()
	if not slotObject then
		slotObject = InventorySection.findFirstEmptySlot()
	end
	return slotObject
end

return findFirstEmptySlot