local Type_Slot = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Type_Slot)
local HotbarSlotsRegistry = {}

HotbarSlotsRegistry.instanceToObjectMap = {}:: {[Frame]: Type_Slot.SlotObject}

return HotbarSlotsRegistry