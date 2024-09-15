--NightVisionGoggles will inherit from the Wearable class
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local nvgogglesRS = ReplicatedStorage.Tools.Wearable["Night Vision Goggles"]
local accessory : Accessory = nvgogglesRS:FindFirstChild("NightVisionGoggles", true)
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
    setmetatable(self, NightVisionGoggles)
    self:intialize()
    return self
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

function NightVisionGoggles:activate()
    if self.canActivate then
        self.canActivate = false
        self.wearing = true 
        playSound(self.soundObjects.onSwitch, nil, 0)
        self.currentCharacterAnimationController.animationTracks.putOn:GetMarkerReachedSignal("overlapped"):Once(function()
            print(if self.currentCharacter then self.currentCharacter.Name else "nil")
            local toolAccessory = self.tool:FindFirstChildWhichIsA("Accessory", true)
            rev_wearAccessory:FireServer(self.currentCharacter, accessory, toolAccessory)
            local cc = nvColorCorrection:Clone()
            cc.Contrast = -1
            cc.TintColor = Color3.fromRGB(255, 255, 255)
            cc.Brightness = 1
            cc.Parent = Lighting
            local tweenTime = self.soundObjects.nightVision.TimeLength
            playSound(self.soundObjects.nightVision, nil, 0)
            TweenService:Create(cc, TweenInfo.new(tweenTime), {Contrast = 0.2}):Play()
            TweenService:Create(cc, TweenInfo.new(tweenTime), {Brightness = 0.2}):Play()
            TweenService:Create(cc, TweenInfo.new(tweenTime), {TintColor = Color3.fromRGB(22, 148, 0)}):Play()
            TweenService:Create(Lighting, TweenInfo.new(tweenTime), {OutdoorAmbient = Color3.fromRGB(255, 255, 255)}):Play()
        end)
        NightVisionGoggles:PutOn(self)
        self.currentCharacterAnimationController.animationTracks.idle:Stop()
        self.viewModelController.animationController.animationTracks.idle:Stop()
    end
    --this is where the actual night vision funcationality comes in, which is unique to this class only
    --[[
        This'll make adding items of any class type sooo much easier because I don't have to write boilerplate code. This makes me love OOP.
        Consider composition over inheritance because I heard inheritance can get messy.
    ]]
end

return NightVisionGoggles