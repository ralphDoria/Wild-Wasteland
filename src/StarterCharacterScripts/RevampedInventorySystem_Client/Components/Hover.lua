local SlotType = require("./SlotType")
local TweenService = game:GetService("TweenService")

local Hover = {}

function Hover.applyEffect(slot: SlotType.SlotType)
    TweenService:Create(
        slot.ImageButton, 
        TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge), 
        {Rotation = 180}
    ):Play()
    slot.ImageButton.Size = UDim2.fromScale(0.8, 0.8)
end

function Hover.removeEffect(slot: SlotType.SlotType)
    TweenService:Create(
        slot.ImageButton, 
        TweenInfo.new(0.2), 
        {Rotation = -180}
    ):Play()
    slot.ImageButton.Size = UDim2.fromScale(1, 1)
end

return Hover