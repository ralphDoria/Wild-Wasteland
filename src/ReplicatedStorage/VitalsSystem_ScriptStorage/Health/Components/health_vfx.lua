local References = require("../../Data/References")
local dyingColorCorrection: ColorCorrectionEffect = game:GetService("Lighting"):FindFirstChild("DyingColorCorrection")

local health_vfx = {}

function health_vfx.tweenSaturation(value: number, transitionTime: number)
    if value == dyingColorCorrection.Saturation then return end

    if dyingColorCorrection.Saturation == 0 then
        dyingColorCorrection.Enabled = true
    end

    local saturationTween = References.TweenService:Create(dyingColorCorrection, TweenInfo.new(transitionTime), {Saturation = value})

    saturationTween:Play()
end


return health_vfx