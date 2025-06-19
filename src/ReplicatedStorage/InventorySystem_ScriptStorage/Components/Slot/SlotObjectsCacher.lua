local Type_Slot = require("./Type_Slot")

local SlotObjectsCacher = {}

SlotObjectsCacher.FilledSlots = {}
SlotObjectsCacher.WearableSlots = {}
SlotObjectsCacher.InitializedSlots = {}

function SlotObjectsCacher.GetSlotFromTool(tool : Tool) : Type_Slot.SlotObject?
    for _, v in SlotObjectsCacher.FilledSlots do
        if v.tool == tool then
            return v
        end
    end
    return nil
end

function SlotObjectsCacher.GetSlotFromInstanceSlot(instance : Frame) : Type_Slot.SlotObject?
    for _, v in SlotObjectsCacher.InitializedSlots do
        if v._itself == instance then
            return v
        end
    end
    return nil
end

return SlotObjectsCacher