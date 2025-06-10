local SlotType = require("./../SlotType")

local FilledSlotsTracker = {}

FilledSlotsTracker.FilledSlots = {}
FilledSlotsTracker.WearableSlots = {}

function FilledSlotsTracker.GetSlotFromTool(tool : Tool) : SlotType.SlotType?
    for _, v in FilledSlotsTracker.FilledSlots do
        if v.tool == tool then
            return v
        end
    end
    return nil
end

function FilledSlotsTracker.GetSlotFromInstanceSlot(instance : Frame) : SlotType.SlotType?
    for _, v in FilledSlotsTracker.FilledSlots do
        if v._itself == instance then
            return v
        end
    end
    return nil
end

return FilledSlotsTracker