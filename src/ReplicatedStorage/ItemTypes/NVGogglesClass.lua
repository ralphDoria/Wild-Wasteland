--NightVisionGoggles will inherit from the Wearable class
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:FindFirstChildOfClass("Humanoid")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local CAS = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local gui : ScreenGui = player.PlayerGui:FindFirstChild("NightVisionGoggles")
local grain : ImageLabel = gui.VHS_grain
local bindName = "VHS_grain"

local nvgogglesRS = ReplicatedStorage.Tools.Wearable["Night Vision Goggles"]
local accessory : Accessory = nvgogglesRS:FindFirstChildWhichIsA("Accessory", true)
local nvColorCorrection : ColorCorrectionEffect = nvgogglesRS:FindFirstChildWhichIsA("ColorCorrectionEffect", true)
local rev_wearAccessory : RemoteEvent = nvgogglesRS:FindFirstChild("wearAccessory", true)
local rev_takeOffAccessory : RemoteEvent = nvgogglesRS:FindFirstChild("takeOffAccessory", true)
local inventoryAndHotbar = player.PlayerGui.InventoryAndHotbar
local bev_signalPutOn : BindableEvent = inventoryAndHotbar:FindFirstChild("SignalPutOn", true)
local bev_signalTakeOff : BindableEvent = inventoryAndHotbar:FindFirstChild("SignalTakeOff", true)

local NightVisionGoggles = {}
NightVisionGoggles.__index = NightVisionGoggles
local Wearable = require(game:GetService("ReplicatedStorage"):FindFirstChild("WearableItemType", true))
setmetatable(NightVisionGoggles, Wearable)

function NightVisionGoggles.new(tool : Tool)
    --INHERITING FROM:
    local self = Wearable.new(tool)
    --PROPERTIES:
    self.soundObjects.onSwitch = tool.BodyAttach.Sounds.OnSwitch
    self.soundObjects.offSwitch = tool.BodyAttach.Sounds.OffSwitch
    self.soundObjects.nightVision = tool.BodyAttach.Sounds["Night Vision"]
    self.clicks = 0 --for double clicking feature
    --GETTING EQUIP TIME AND WEAR TIME:
    local putOnTrack = character:FindFirstChildWhichIsA("Animator", true):LoadAnimation(self.animObjects.putOn)
    local equipTrack = character:FindFirstChildWhichIsA("Animator", true):LoadAnimation(self.animObjects.equip)
    local loadTime = 0
    while putOnTrack.Length == 0 or equipTrack.Length == 0 do
        loadTime += task.wait()
    end
    tool:SetAttribute("wearTime", putOnTrack.Length)
    tool:SetAttribute("equipTime", equipTrack.Length)
    putOnTrack:Destroy()
    equipTrack:Destroy()
    loadTime = nil
    --OOP SETUP:
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
    table.insert(
        self.connections,
        bev_signalPutOn.Event:Connect(function(thisTool : Tool, firingDirection : number)
            --[[
            Firing direction key:
            1 - from inventory to tool
            2 - from tool to inventory
            ]]
            if firingDirection == 1 then
                if thisTool == self.tool then
                    print("put on signal received from inventory to tool code")
                    --check if tool has to be equipped
                    local unequipped = self.tool.Parent:FindFirstChild("Humanoid") == nil
                    if unequipped then
                        humanoid:EquipTool(self.tool)
                        local waitingTime = 0
                        while self.canActivate == false do
                            waitingTime += task.wait()
                        end
                        print(task.wait())
                        self:wearGoggles()
                    else
                        self:wearGoggles()
                    end
                end
            end
        end)
        --[[
        self.tool:GetAttributeChangedSignal("WearingViaGui"):Once(function()
            if self.tool:GetAttribute("WearingViaGui") == true then
                --check if tool has to be equipped
                local unequipped = self.tool.Parent:FindFirstChild("Humanoid") == nil
                if unequipped then
                    humanoid:EquipTool(self.tool)
                    local waitingTime = 0
                    while self.canActivate == false do
                        waitingTime += task.wait()
                    end
                    print(task.wait())
                    self:wearGoggles()
                else
                    self:wearGoggles()
                end
            end
        end)
        ]]
    )
    --in here will be events specific to the night vision goggles
end

local function nvEffectOff()
    Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
    Lighting.ExposureCompensation = 0
    for _, v in Lighting:GetChildren() do
        if v:IsA("ColorCorrectionEffect") and v.Name == "NV_ColorCorrection" then
            local ti = TweenInfo.new(0.5)
            local tweenBrightness = TweenService:Create(v, ti, {Brightness = -1})
            local tweenTint = TweenService:Create(v, ti, {TintColor = Color3.new(0, 0, 0)})
            tweenBrightness.Completed:Once(function()
                v:Destroy()
                ti = nil
            end)
            tweenTint:Play()
            tweenBrightness:Play()
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
        --print("the functionality of this is being transferred, this is obsolete")
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
    self.charAnimController.animationTracks.putOn:GetMarkerReachedSignal("overlapped"):Once(function()
        local toolAccessory = self.tool:FindFirstChildWhichIsA("Accessory", true)
        self.vmController:hideViewModelTool()
        playSound(self.soundObjects.nightVision, nil, 0.1)
        nvEffectOn(self)
        rev_wearAccessory:FireServer(character, accessory, toolAccessory, self.tool)
        CAS:BindAction("debugTakeOff", function(actionName, inputState, _inputObject)
            if inputState == Enum.UserInputState.Begin then
                --print("debugTakeOff")
                self:TakeOff()
                CAS:UnbindAction("debugTakeOff")
            end
        end, true, Enum.KeyCode.Y)
    end)
    self.charAnimController.animationTracks.putOn:GetMarkerReachedSignal("startBlur"):Once(function()
        putOnBlur()
    end)
    NightVisionGoggles:PutOn(self)
    self.charAnimController.animationTracks.idle:Stop()
    self.vmController.animationController.animationTracks.idle:Stop()
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
            bev_signalPutOn:Fire(self.tool, 2)
            --self.tool:SetAttribute("SignalingPutOn", true)
            self:wearGoggles()
        end
    end
end

function NightVisionGoggles:equip()
    if self.tool:GetAttribute("SignalingTakeOff") == false or self.tool:GetAttribute("SignalingTakeOff") == nil then
        Wearable:equip(self, tableOfFunctions)
    end 
end

function NightVisionGoggles:TakeOff()
    --print("nvgoggles's :TakeOff()")
    playSound(self.soundObjects.offSwitch, nil, 0)
    self.canActivate = false
    bev_signalTakeOff:Fire(self.tool, 2)
    --self.tool:SetAttribute("SignalingTakeOff", true)
    humanoid:EquipTool(self.tool)
    self.charAnimController.animationTracks.putOn:GetMarkerReachedSignal("overlapped"):Once(function()
        rev_takeOffAccessory:FireServer(character, accessory.Name, self.tool)
        nvEffectOff()
    end)
    self.charAnimController.animationTracks.putOn.Ended:Once(function()
        self.canActivate = true
        self.tool:SetAttribute("isWearing", false)
    end)
    Wearable:equip(self, nil, {
        charAnimTrack = self.charAnimController.animationTracks.putOn,
        vmAnimTrack = self.vmController.animationController.animationTracks.putOn,
        fadeTime = 0.1,
        weight = 1,
        speed = -1
    })
    --[[
    self.charAnimController.animationTracks.putOn:Play(0.1,1,-1)
    self.vmController.animationController.animationTracks.putOn:Play(0.1,1,-1)
    self.charAnimController.animationTracks.idle:Play()
    self.vmController.animationController.animationTracks.idle:Play()
    ]]
end

return NightVisionGoggles