local Wearable = require("./../../Subclasses/Wearable")

local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

-- for NV effects
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Instances = ReplicatedStorage.ItemSystem_Storage.ToolCatalog["NV Goggles"].Instances:: Folder
local NV_Gui = Instances.NV_Gui:: ScreenGui
local vhsGrain = NV_Gui.vhsGrain:: ImageLabel
NV_Gui.Enabled = false

NV_Gui.Parent = game:GetService("Players").LocalPlayer.PlayerGui
local NV_CC: ColorCorrectionEffect = Instances.NV_ColorCorrection
local baseColorCorrectionValues = {
    TintColor = NV_CC.TintColor,
    Contrast = NV_CC.Contrast,
    Brightness = NV_CC.Brightness
}
local NV_Blur: BlurEffect = Instance.new("BlurEffect")
NV_Blur.Name = "NV_Blur"
NV_Blur.Parent = Instances
local vhsEffectBindName = "vhsEffectForNVG"
local nightVisionSFX_time: number

type NVGogglesObject = Wearable.WearableType & {

}

local NVGoggles = {}

function NVGoggles.new(tool: Tool, humanoid: Humanoid): NVGogglesObject
    local self = Wearable.new(tool, humanoid)

    if nightVisionSFX_time == nil then
        nightVisionSFX_time = self.soundManager.Sounds[self.tool.Name].nightVision.TimeLength
    end
    NVGoggles._initialize(self)

    return self
end

local function putOnBlur()
    NV_Blur.Name = "nvBlur"
    NV_Blur.Size = 0
    NV_Blur.Parent = Lighting
    local fadeInBlur = TweenService:Create(NV_Blur, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = 56})
    local fadeOutBlur = TweenService:Create(NV_Blur, TweenInfo.new(1), {Size = 0})
    fadeInBlur:Play()
    fadeInBlur.Completed:Wait()
    fadeOutBlur:Play()
    fadeOutBlur.Completed:Once(function()
        NV_Blur.Parent = Instances
    end)
end

local function toggleNVEffect(self: NVGogglesObject, toggle: boolean)
    if toggle then
        NV_Gui.Enabled = true
        RunService:BindToRenderStep(vhsEffectBindName, 200, function()
            vhsGrain.TileSize = UDim2.new(math.random(7, 10) / 10, 0, math.random(7, 10) / 10, 0)
        end)
        local ti = TweenInfo.new(nightVisionSFX_time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
        --for that brief flash effect
        NV_CC.Brightness = 1
        NV_CC.Contrast = -1
        NV_CC.Saturation = -1
        NV_CC.Parent = Lighting
        -- modified properties of color correction: Tint Color, Saturation, Contrast, Brightness
        TweenService:Create(NV_CC, ti, {TintColor = baseColorCorrectionValues.TintColor}):Play()
        TweenService:Create(NV_CC, ti, {Contrast = baseColorCorrectionValues.Contrast}):Play()
        TweenService:Create(NV_CC, ti, {Brightness = baseColorCorrectionValues.Brightness}):Play()
        -- modified properties of Lighting service: ExposureCompensation (0.8) 
        Lighting.ExposureCompensation = 0.8
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        --[[
        TweenService:Create(Lighting, ti, {ExposureCompensation = 0.8}):Play()
        TweenService:Create(Lighting, ti, {OutdoorAmbient = Color3.new(1, 1, 1)}):Play()
        ]]
    else
        local fadeToBlack = TweenService:Create(NV_CC, TweenInfo.new(0.2), {TintColor = Color3.new(0, 0, 0)})
        local fadeToNormal = TweenService:Create(NV_CC, TweenInfo.new(0.2), {TintColor = Color3.new(1, 1, 1)})
        fadeToBlack:Play()
        fadeToBlack.Completed:Wait()
        task.wait(0.2)
        NV_Gui.Enabled = false
        RunService:UnbindFromRenderStep(vhsEffectBindName)
        -- modified properties of color correction: Tint Color, Saturation, Contrast, Brightness
        TweenService:Create(NV_CC, TweenInfo.new(0), {Saturation = 0}):Play() --this cancels any currently playing tweens just in case turnOnNVEffect is still in progress
        TweenService:Create(NV_CC, TweenInfo.new(0), {Contrast = 0}):Play()
        TweenService:Create(NV_CC, TweenInfo.new(0), {Brightness = 0}):Play()
        Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
        Lighting.ExposureCompensation = 0
        fadeToNormal:Play()
        fadeToNormal.Completed:Wait()
        NV_CC.Parent = Instances
    end
end

function NVGoggles._initialize(self: NVGogglesObject)
    Wearable.initialize(
        self, 
        function() -- onWearing
            self.soundManager.playSound("Client", self.soundManager.Sounds[self.tool.Name].onSwitch :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0)
        end,
        function() -- onUnwearing
            self.soundManager.playSound("Client", self.soundManager.Sounds[self.tool.Name].offSwitch :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0.1)
            task.spawn(function()
                toggleNVEffect(self, false)
            end)
        end,
        function() -- appyWornEffects 
            self.soundManager.playSound("Client", self.soundManager.Sounds[self.tool.Name].nightVision :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0.1)
            task.spawn(function()
                toggleNVEffect(self, true)
            end)
        end, 
        function() -- removeWornEffects
            
        end
    )

    local wearTrack = self.animManager.animationTracks[self.tool.Name].wear
    self.connections.wearTrackStartBlur = wearTrack:GetMarkerReachedSignal("startBlur"):Connect(function()
        if self.State == "Equipping" then
            putOnBlur() 
        end
    end)
end

return NVGoggles