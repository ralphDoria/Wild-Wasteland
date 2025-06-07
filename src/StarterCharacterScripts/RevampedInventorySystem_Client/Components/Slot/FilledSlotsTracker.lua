local SlotType = require("./../SlotType")

local FilledSlotsTracker = {}

FilledSlotsTracker.FilledSlots = {}

function FilledSlotsTracker.GetSlotFromTool(tool : Tool) : SlotType.SlotType?
    for _, v in FilledSlotsTracker.FilledSlots do
        if v.tool == tool then
            return v
        end
    end
    return nil
end

return FilledSlotsTracker