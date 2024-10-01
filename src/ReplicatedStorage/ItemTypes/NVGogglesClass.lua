--NightVisionGoggles will inherit from the Wearable class
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local gui : ScreenGui = player.PlayerGui:FindFirstChild("NightVisionGoggles")
local grain : ImageLabel = gui.VHS_grain
local bindName = "VHS_grain"

local nvgogglesRS = ReplicatedStorage.Tools.Wearable["Night Vision Goggles"]
local accessory : Accessory = nvgogglesRS:FindFirstChildWhichIsA("Accessory", true)
local nvColorCorrection : ColorCorrectionEffect = nvgogglesRS:FindFirstChildWhichIsA("ColorCorrectionEffect", true)
local rev_wearAccessory : RemoteEvent = nvgogglesRS:FindFirstChild("wearAccessory", true)

local NightVisionGoggles = {}
NightVisionGoggles.__index = NightVisionGoggles
local Wearable = require(game:GetService("ReplicatedStorage"):FindFirstChild("WearableItemType", true))
setmetatable(NightVisionGoggles, Wearable)

function NightVisionGoggles.new(tool : Tool)
    local self = Wearable.new(tool)
    --[[
    LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE,
    LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE,
    LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE, LOOK HERE

    You need to find a way to give this class (the final child class) access to ViewModelController and AnimationController because those
    need to be created here. I feel close to getting this inheritance thing down
    ]]
    self.soundObjects.onSwitch = tool.BodyAttach.Sounds.OnSwitch
    self.soundObjects.offSwitch = tool.BodyAttach.Sounds.OffSwitch
    self.soundObjects.nightVision = tool.BodyAttach.Sounds["Night Vision"]
    self.viewModelController = self.VMController.new(workspace.CurrentCamera:WaitForChild("viewModel"), tool, self.animObjects, hrp)
    self.currentCharacter = nil
    self.clicks = 0 --for double clicking feature
    setmetatable(self, NightVisionGoggles)
    self:intialize()
    return self
end 

local function nvEffectOff()
    Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    Lighting.ExposureCompensation = 0
    for _, v in Lighting:GetChildren() do
        if v:IsA("ColorCorrectionEffect") and v.Name == "NV_ColorCorrection" then
            v:Destroy()
        end
    end
    gui.Enabled = false
    RunService:UnbindFromRenderStep(bindName)
end

local tableOfFunctions = {
    deathProcedure = function()
        nvEffectOff()
        --print("cleaning up nv effects")
    end,
    forceWear = function(subclassObject)
        --print("forceWear = " .. tostring(subclassObject.tool:GetAttribute("forceWear")))
        if subclassObject.tool:GetAttribute("forceWear") == true then
            NightVisionGoggles:wearGoggles(subclassObject)
        end
    end
}

local function nvEffectOn(subclassObject)
    gui.Enabled = true
    RunService:BindToRenderStep(bindName, 200, function()
        grain.TileSize = UDim2.new(math.random(7, 10) / 10, 0, math.random(7, 10) / 10, 0)
    end)
    local cc = nvColorCorrection:Clone()
    cc.Contrast = -1
    cc.TintColor = Color3.fromRGB(255, 255, 255)
    cc.Brightness = 1
    cc.Parent = Lighting
    cc.Saturation = -1
    local tweenTime = subclassObject.soundObjects.nightVision.TimeLength
    Lighting.ExposureCompensation = 3
    TweenService:Create(cc, TweenInfo.new(tweenTime), {Contrast = 0.2}):Play()
    TweenService:Create(cc, TweenInfo.new(tweenTime), {Brightness = 0.2}):Play()
    TweenService:Create(cc, TweenInfo.new(tweenTime), {TintColor = Color3.fromRGB(22, 148, 0)}):Play()
    TweenService:Create(Lighting, TweenInfo.new(tweenTime), {OutdoorAmbient = Color3.fromRGB(255, 255, 255)}):Play()
end

local function putOnBlur()
    local nvBlur : BlurEffect = Instance.new("BlurEffect")
    nvBlur.Name = "nvBlur"
    nvBlur.Size = 0
    nvBlur.Parent = Lighting
    TweenService:Create(nvBlur, TweenInfo.new(1, Enum.EasingStyle.Exponential), {Size = 56}):Play()
    task.wait(1)
    local blurFade = TweenService:Create(nvBlur, TweenInfo.new(0.5), {Size = 0})
    blurFade.Completed:Once(function()
        nvBlur:Destroy()
    end)
    blurFade:Play()
end

function NightVisionGoggles:wearGoggles(subclassObject)
    if subclassObject ~= nil then
        self = subclassObject
    end
    self.canActivate = false
    self.wearing = true 
    playSound(self.soundObjects.onSwitch, nil, 0)
    self.currentCharacterAnimationController.animationTracks.putOn:GetMarkerReachedSignal("overlapped"):Once(function()
        local toolAccessory = self.tool:FindFirstChildWhichIsA("Accessory", true)
        self.viewModelController:hideViewModelTool()
        playSound(self.soundObjects.nightVision, nil, 0.1)
        nvEffectOn(self)
        rev_wearAccessory:FireServer(self.currentCharacter, accessory, toolAccessory, self.tool)
    end)
    self.currentCharacterAnimationController.animationTracks.putOn:GetMarkerReachedSignal("startBlur"):Once(function()
        putOnBlur()
    end)
    NightVisionGoggles:PutOn(self)
    self.currentCharacterAnimationController.animationTracks.idle:Stop()
    self.viewModelController.animationController.animationTracks.idle:Stop()
end

function NightVisionGoggles:activate()
    if self.canActivate then
        self.clicks += 1
        task.spawn(function()
            task.wait(0.5)
            self.clicks = 0
        end)
        if self.clicks >= 2 then
            self.tool:SetAttribute("canDrop", false)
            self.tool:SetAttribute("puttingOn", true)
            self:wearGoggles()
        end
    end
end

function NightVisionGoggles:equip()
    Wearable:equip(self, tableOfFunctions)
end

function NightVisionGoggles:intialize()
    Wearable:initialize(self)
    table.insert(
        self.connections,
        self.tool.Activated:Connect(function()
            self:activate()
        end)
    )
    --in here will be events specific to the night vision goggles
end

return NightVisionGoggles