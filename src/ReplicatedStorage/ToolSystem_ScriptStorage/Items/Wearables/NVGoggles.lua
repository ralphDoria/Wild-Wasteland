local Wearable = require("./../../Subclasses/Wearable")

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

type NVGogglesObject = Wearable.WearableType & {

}

local NVGoggles = {}

function NVGoggles.new(tool: Tool, humanoid: Humanoid): NVGogglesObject
    local self = Wearable.new(tool, humanoid)

    NVGoggles._initialize(self)

    return self
end

-- local function putOnBlur()
--     local nvBlur : BlurEffect = Instance.new("BlurEffect")
--     nvBlur.Name = "nvBlur"
--     nvBlur.Size = 0
--     nvBlur.Parent = Lighting
--     local fadeInBlur = TweenService:Create(nvBlur, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = 56})
--     local fadeOutBlur = TweenService:Create(nvBlur, TweenInfo.new(1), {Size = 0})
--     fadeInBlur:Play()
--     fadeInBlur.Completed:Wait()
--     fadeOutBlur.Completed:Once(function()
--         nvBlur:Destroy()
--     end)
--     fadeOutBlur:Play()
-- end

-- local function turnOnNVEffect(subclassObject)
--     gui.Enabled = true
--     RunService:BindToRenderStep(bindName, 200, function()
--         grain.TileSize = UDim2.new(math.random(7, 10) / 10, 0, math.random(7, 10) / 10, 0)
--     end)
--     local ti = TweenInfo.new(subclassObject.soundObjects.nightVision.TimeLength, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
--     local cc = Instance.new(nvColorCorrection.ClassName)
--     cc.Name = nvColorCorrection.Name
--     --for that brief flash effect
--     cc.Brightness = 1
--     cc.Contrast = -1
--     cc.Saturation = -1
--     cc.Parent = Lighting
--     -- modified properties of color correction: Tint Color, Saturation, Contrast, Brightness
--     TweenService:Create(cc, ti, {TintColor = nvColorCorrection.TintColor}):Play()
--     TweenService:Create(cc, ti, {Contrast = nvColorCorrection.Contrast}):Play()
--     TweenService:Create(cc, ti, {Brightness = nvColorCorrection.Brightness}):Play()
--     -- modified properties of Lighting service: ExposureCompensation (0.8) 
--     Lighting.ExposureCompensation = 0.8
--     Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
--     --[[
--     TweenService:Create(Lighting, ti, {ExposureCompensation = 0.8}):Play()
--     TweenService:Create(Lighting, ti, {OutdoorAmbient = Color3.new(1, 1, 1)}):Play()
--     ]]
-- end

-- local function turnOffNVEffect(subclassObject)
--     local cc : ColorCorrectionEffect = Lighting:FindFirstChild(nvColorCorrection.Name)
--     local fadeToBlack = TweenService:Create(cc, TweenInfo.new(0.2), {TintColor = Color3.new(0, 0, 0)})
--     local fadeToNormal = TweenService:Create(cc, TweenInfo.new(0.2), {TintColor = Color3.new(1, 1, 1)})
--     fadeToBlack:Play()
--     fadeToBlack.Completed:Wait()
--     task.wait(0.2)
--     gui.Enabled = false
--     RunService:UnbindFromRenderStep(bindName)
--     -- modified properties of color correction: Tint Color, Saturation, Contrast, Brightness
--     TweenService:Create(cc, TweenInfo.new(0), {Saturation = 0}):Play() --this cancels any currently playing tweens just in case turnOnNVEffect is still in progress
--     TweenService:Create(cc, TweenInfo.new(0), {Contrast = 0}):Play()
--     TweenService:Create(cc, TweenInfo.new(0), {Brightness = 0}):Play()
--     Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
--     Lighting.ExposureCompensation = 0
--     fadeToNormal:Play()
--     fadeToNormal.Completed:Wait()
--     cc:Destroy()
-- end

function NVGoggles._initialize(self: NVGogglesObject)
    Wearable.initialize(
        self, 
        function() -- appyWornEffects 

        end, 
        function() -- removeWornEffects
            
        end
    )
end

return NVGoggles