local Type_Slot = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Type_Slot)
local SlotRegistry = {}

SlotRegistry.instanceToObjectMap = {}:: {[Frame]: Type_Slot.SlotObject}
SlotRegistry.toolToObjectMap = {}:: {[Tool]: Type_Slot.SlotObject}
SlotRegistry.wearableCategoryToObjectMap = {}:: {[string]: Type_Slot.SlotObject}

return SlotRegistry