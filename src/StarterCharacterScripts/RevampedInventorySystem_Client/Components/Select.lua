local SlotType = require("./SlotType")

local Select = {}

Select.current = nil

function Select.applyEffect(slot: SlotType.SlotType)
    local uiCorner = slot.InnerFrame:FindFirstChildOfClass("UICorner")
    if uiCorner then
        warn("select effect already applied to this slot") 
        return 
    end

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = slot.InnerFrame
end

function Select.removeEffect(slot: SlotType.SlotType)
    local uiCorner = slot.InnerFrame:FindFirstChildOfClass("UICorner")
    if uiCorner then
        uiCorner:Destroy()
    end
end

return Select