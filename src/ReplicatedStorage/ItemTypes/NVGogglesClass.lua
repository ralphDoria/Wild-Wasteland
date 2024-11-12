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
                        --local waitingTime = 0
                        while self.canActivate == false do
                            task.wait()
                            --waitingTime += task.wait()
                        end
                        --[[
                        print(self.canActivate)
                        print(waitingTime)
                        ]]
                        self:wearGoggles()
                    else
                        self:wearGoggles()
                    end
                end
            end
        end)
    )
    table.insert(
        self.connections,
        bev_signalTakeOff.Event:Connect(function(thisTool : Tool, firingDirection : number)
            --[[
            Firing direction key:
            1 - from inventory to tool
            2 - from tool to inventory
            ]]
            if firingDirection == 1 then
                if thisTool == self.tool then
                    --print("take off signal received from inventory to tool code")
                    self:TakeOff(true)
                end
            end
        end)
    )
    --in here will be events specific to the night vision goggles
end

local function turnOffNVEffect(subclassObject)
    local cc : ColorCorrectionEffect = Lighting:FindFirstChild(nvColorCorrection.Name)
    local fadeToBlack = TweenService:Create(cc, TweenInfo.new(0.2), {TintColor = Color3.new(0, 0, 0)})
    local fadeToNormal = TweenService:Create(cc, TweenInfo.new(0.2), {TintColor = Color3.new(1, 1, 1)})
    fadeToBlack:Play()
    fadeToBlack.Completed:Wait()
    task.wait(0.2)
    gui.Enabled = false
    RunService:UnbindFromRenderStep(bindName)
    -- modified properties of color correction: Tint Color, Saturation, Contrast, Brightness
    TweenService:Create(cc, TweenInfo.new(0), {Saturation = 0}):Play() --this cancels any currently playing tweens just in case turnOnNVEffect is still in progress
    TweenService:Create(cc, TweenInfo.new(0), {Contrast = 0}):Play()
    TweenService:Create(cc, TweenInfo.new(0), {Brightness = 0}):Play()
    Lighting.OutdoorAmbient = Color3.new(0, 0, 0)
    Lighting.ExposureCompensation = 0
    fadeToNormal:Play()
    fadeToNormal.Completed:Wait()
    cc:Destroy()
end

local tableOfFunctions = {
    deathProcedure = function(subclassObject)
        turnOffNVEffect(subclassObject)
        --print("cleaning up nv effects")
    end,
    forceWear = function(subclassObject)
        --print("the functionality of this is being transferred, this is obsolete")
    end
}

local function turnOnNVEffect(subclassObject)
    gui.Enabled = true
    RunService:BindToRenderStep(bindName, 200, function()
        grain.TileSize = UDim2.new(math.random(7, 10) / 10, 0, math.random(7, 10) / 10, 0)
    end)
    local ti = TweenInfo.new(subclassObject.soundObjects.nightVision.TimeLength, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local cc = Instance.new(nvColorCorrection.ClassName)
    cc.Name = nvColorCorrection.Name
    --for that brief flash effect
    cc.Brightness = 1
    cc.Contrast = -1
    cc.Saturation = -1
    cc.Parent = Lighting
    -- modified properties of color correction: Tint Color, Saturation, Contrast, Brightness
    TweenService:Create(cc, ti, {TintColor = nvColorCorrection.TintColor}):Play()
    TweenService:Create(cc, ti, {Contrast = nvColorCorrection.Contrast}):Play()
    TweenService:Create(cc, ti, {Brightness = nvColorCorrection.Brightness}):Play()
    -- modified properties of Lighting service: ExposureCompensation (0.8) 
    Lighting.ExposureCompensation = 0.8
    Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
    --[[
    TweenService:Create(Lighting, ti, {ExposureCompensation = 0.8}):Play()
    TweenService:Create(Lighting, ti, {OutdoorAmbient = Color3.new(1, 1, 1)}):Play()
    ]]
end

local function putOnBlur()
    local nvBlur : BlurEffect = Instance.new("BlurEffect")
    nvBlur.Name = "nvBlur"
    nvBlur.Size = 0
    nvBlur.Parent = Lighting
    local fadeInBlur = TweenService:Create(nvBlur, TweenInfo.new(0.2, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Size = 56})
    local fadeOutBlur = TweenService:Create(nvBlur, TweenInfo.new(1), {Size = 0})
    fadeInBlur:Play()
    fadeInBlur.Completed:Wait()
    fadeOutBlur.Completed:Once(function()
        nvBlur:Destroy()
    end)
    fadeOutBlur:Play()
end

function NightVisionGoggles:wearGoggles(subclassObject)
    if subclassObject ~= nil then
        self = subclassObject
    end
    self.tool:SetAttribute("canDrop", false)
    self.canActivate = false
    self.wearing = true 
    playSound(self.soundObjects.onSwitch, nil, 0)
    self.charAnimController.animationTracks.putOn:GetMarkerReachedSignal("overlapped"):Once(function()
        local toolAccessory = self.tool:FindFirstChildWhichIsA("Accessory", true)
        print("hiding viewmodel tool")
        self.vmController:hideViewModelTool()
        playSound(self.soundObjects.nightVision, nil, 0.1)
        turnOnNVEffect(self)
        rev_wearAccessory:FireServer(character, accessory, toolAccessory, self.tool)
    end)
    self.charAnimController.animationTracks.putOn:GetMarkerReachedSignal("startBlur"):Once(function()
        putOnBlur()
    end)
    self.charAnimController.animationTracks.putOn.Ended:Once(function()

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
            bev_signalPutOn:Fire(self.tool, 2) --this is specifically for when equipping a wearable item by double clicking
            self:wearGoggles()
        end
    end
end

function NightVisionGoggles:equip()
    if not self.tool:GetAttribute("NegateDefaultEquip") then
        --print("calling normal equip function")
        Wearable:equip(self, tableOfFunctions)
    end 
end

function NightVisionGoggles:TakeOff(signaledFromGui : boolean)
    --print("nvgoggles's :TakeOff()")
    task.spawn(function()
        turnOffNVEffect(self)
    end)
    playSound(self.soundObjects.offSwitch, nil, 0)
    self.canActivate = false
    if not signaledFromGui then
        bev_signalTakeOff:Fire(self.tool, 2)
    end
    self.tool:SetAttribute("NegateDefaultEquip", true)
    local cachedTool = character:FindFirstChildOfClass("Tool")
    humanoid:EquipTool(self.tool)
    self.charAnimController.animationTracks.putOn:GetMarkerReachedSignal("overlapped"):Once(function()
        rev_takeOffAccessory:FireServer(character, accessory.Name, self.tool)
        --[[
        for _, v in self.tool:FindFirstChild("ToolModel"):GetDescendants() do
            if v:IsA("BasePart") or v:IsA("MeshPart") then
                v.LocalTransparencyModifier = 1
            end
        end
        ]]
    end)
    self.charAnimController.animationTracks.putOn.Ended:Once(function()
        self.tool:SetAttribute("isWearing", false)
        self.tool:SetAttribute("NegateDefaultEquip", false)
    end)
    self.charAnimController.animationTracks.putOn.Stopped:Once(function()
        --print("\"Firing\" ForceDropNow")
        self.tool:SetAttribute("ForceDropNow", true)
        if cachedTool then
            humanoid:EquipTool(cachedTool)
        end
    end)
    Wearable:equip(self, nil, {
        charAnimTrack = self.charAnimController.animationTracks.putOn,
        vmAnimTrack = self.vmController.animationController.animationTracks.putOn,
        fadeTime = 0.1,
        weight = 1,
        speed = -1
    })
end

return NightVisionGoggles