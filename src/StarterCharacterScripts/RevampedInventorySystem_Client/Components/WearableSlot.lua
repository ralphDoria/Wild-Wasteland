local Slot = require("./Slot")
local SlotType = require("./SlotType")
export type WearableSlotType = SlotType.SlotType & {
    
}

local WearableSlot = {}

function WearableSlot.new(): WearableSlotType
    local slot = Slot.new("Wearable")
    return slot
end

return WearableSlot