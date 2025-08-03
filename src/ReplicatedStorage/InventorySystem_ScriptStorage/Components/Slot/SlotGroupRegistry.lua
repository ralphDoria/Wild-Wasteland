local Type_SlotGroup = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Type_SlotGroup)

local SlotGroupRegistry = {}

SlotGroupRegistry.instanceToObjectMap = {}:: {[Frame]: Type_SlotGroup.object}

return SlotGroupRegistry