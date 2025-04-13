local References = require("../../Data/References")
local dyingColorCorrection: ColorCorrectionEffect = game:GetService("Lighting"):FindFirstChild("DyingColorCorrection")

local baseColor = Color3.new(255, 255, 255)
local endColor = Color3.new(0, 0, 255)
local targetColor = baseColor

local health_vfx = {}

function health_vfx.tweenDyingColorCorrectionTo(value: number, transitionTime: number)
    if value == dyingColorCorrection.Saturation then return end

    if dyingColorCorrection.Saturation == 0 then
        dyingColorCorrection.Enabled = true
    end

    local saturationTween = References.TweenService:Create(dyingColorCorrection, TweenInfo.new(transitionTime), {Saturation = value})

    saturationTween:Play()
end

function health_vfx.updateStatGuiColor()
    
end

return health_vfx