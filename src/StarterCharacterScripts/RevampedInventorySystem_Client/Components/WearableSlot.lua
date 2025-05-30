local Slot = require("./Slot")
local SlotType = require("./SlotType")
export type WearableSlotType = SlotType.SlotType & {
    wearableSlot: boolean
}

local WearableSlot = {}

function WearableSlot.new(): WearableSlotType
    local slot = Slot.new("Wearable")
    slot.wearableSlot = true
    return slot
end

return WearableSlot