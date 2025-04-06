local References = require("./References")
local TweenService = game:GetService("TweenService")
local statGui: CanvasGroup = References.CharacterStatsGui.Frame.health
local statGuiObject = References.StatGuiManager.new(statGui, "Health", Color3.fromRGB(255, 0, 0))
local RunService = game:GetService("RunService")

--Sounds
local sounds: {[string]: Sound} = {
    earsRinging = References.debuffSounds.Health.EarsRinging,
    heartbeat = References.debuffSounds.Health.Heartbeat
}
local heartbeatPitch = sounds.heartbeat:FindFirstChildOfClass("PitchShiftSoundEffect"):: PitchShiftSoundEffect

--Audio FX
local gameSG: SoundGroup = References.SoundService["0 - Master"]:FindFirstChild("Game", true)
local dyingReverb: ReverbSoundEffect = game:GetService("SoundService"):FindFirstChild("DyingReverb", true)

--Visuals
local effectsOverlay = References.playerGui:WaitForChild("EffectsOverlay")
effectsOverlay.Enabled = true
local bloodUi: CanvasGroup = effectsOverlay.Blood
local dyingColorCorrection: ColorCorrectionEffect = game:GetService("Lighting"):FindFirstChild("DyingColorCorrection")

local connections = {}

local function tweenHeartbeatSpeedTo(value: number, transitionTime: number): Tween?
    if sounds.heartbeat.PlaybackSpeed == value then return end
    value = math.clamp(value, 0, 2)
    local ti = TweenInfo.new(transitionTime, Enum.EasingStyle.Linear)
    local speedTween = TweenService:Create(sounds.heartbeat, ti, {PlaybackSpeed = value})
    local pitchTween = TweenService:Create(heartbeatPitch, ti, {Octave = 1/value})
    speedTween:Play()
    pitchTween:Play()
    return speedTween
end

local function tweenSoundVolume(sound: Sound, newVolume: number, transitionTime: number)
    if newVolume == sound.Volume then  return end

    if sound.Volume == 0 then
        sound:Play()
    end

    local soundTween = TweenService:Create(sound, TweenInfo.new(transitionTime), {Volume = newVolume})

    if newVolume == 0 then
        soundTween.Completed:Once(function(a0: Enum.PlaybackState)  
            sound:Stop()
        end) 
    end

    soundTween:Play()
end

local function tweenDyingReverbTo(value: number, transitionTime: number)
    if value == dyingReverb.WetLevel then return end

    if dyingReverb.WetLevel == -30 then
        dyingReverb.Enabled = true
    end

    local reverbTween = TweenService:Create(dyingReverb, TweenInfo.new(transitionTime), {WetLevel = value})

    if value == -30 then
        reverbTween.Completed:Once(function(a0: Enum.PlaybackState)  
            dyingReverb.Enabled = false
        end) 
    end

    reverbTween:Play()
end

local function tweenDyingColorCorrectionTo(value: number, transitionTime: number)
    if value == dyingColorCorrection.Saturation then return end

    if dyingColorCorrection.Saturation == 0 then
        dyingColorCorrection.Enabled = true
    end

    local saturationTween = TweenService:Create(dyingColorCorrection, TweenInfo.new(transitionTime), {Saturation = value})

    saturationTween:Play()
end

local function tweenGameAudioVolumeTo(value: number, transitionTime: number)
    if value == gameSG.Volume then return end
    local volumeTween = TweenService:Create(gameSG, TweenInfo.new(transitionTime), {Volume = value})
    volumeTween:Play()
end

local proportionMarkers = {
    startHeartbeat = 0.5, -- also when color correction starts
    startEarRinging = 0.2, -- also when reverb starts
    dead = 0
}

local baseHeartbeatSpeed = 1
local maxHeartbeatSpeed = 2

local function updateHeartbeatSoundProperties(healthProportion: number)
    if healthProportion > proportionMarkers.startHeartbeat then
        tweenHeartbeatSpeedTo(baseHeartbeatSpeed, 1)
        tweenSoundVolume(sounds.heartbeat, 0, 0.5)
    elseif healthProportion > proportionMarkers.dead then
        local heartbeatSpeed = math.clamp(math.map(healthProportion, proportionMarkers.startHeartbeat, proportionMarkers.dead, baseHeartbeatSpeed, maxHeartbeatSpeed), baseHeartbeatSpeed, maxHeartbeatSpeed)
        --print(heartbeatSpeed)
        tweenHeartbeatSpeedTo(heartbeatSpeed, 0.5)
        tweenSoundVolume(sounds.heartbeat, 1, 0.5)
        tweenDyingColorCorrectionTo(
            math.clamp(math.map(healthProportion, proportionMarkers.startHeartbeat, proportionMarkers.dead, 0, -1), -1, 0), 
            0.5)
        tweenGameAudioVolumeTo(
            math.clamp(math.map(healthProportion, proportionMarkers.startHeartbeat, proportionMarkers.dead, 1, 0.2), 0.2, 1), 
            0.5)
    elseif healthProportion <= proportionMarkers.dead then
        local tween = tweenHeartbeatSpeedTo(0.3, 3)
        tween.Completed:Once(function(a0: Enum.PlaybackState)
            tweenSoundVolume(sounds.heartbeat, 0, 5)
            -- warn("last heartbeat")--tween Heratbeat volume to 0 rather than one last heartbeat
            -- sounds.heartbeat.DidLoop:Once(function(a0: string, a1: number)
            --     warn("stopping heartbeat")
            --     sounds.heartbeat:Stop()
            -- end)
        end)
    end
end

local function updateEarRingingSoundProperties(healthProportion: number)
    if healthProportion > proportionMarkers.startEarRinging then -- possible healthProportion values here: (0.2, inf)
        tweenSoundVolume(sounds.earsRinging, 0, 0.5)
    elseif healthProportion > proportionMarkers.dead then -- possible healthProportion values here: (0, 0.2]
        tweenSoundVolume(sounds.earsRinging, 0.5, 0.5)
        tweenDyingReverbTo(
            math.clamp(math.map(healthProportion, proportionMarkers.startEarRinging, proportionMarkers.dead, -30, 20), -30, 20), 
            0.5)
    elseif healthProportion <= proportionMarkers.dead then -- possible healthProportion values here: (-inf, 0]
        tweenSoundVolume(sounds.earsRinging, 0, 4)
    end
end

local Health = {}

local function toggleBloodGuiHeartbeatSync(toggle: boolean)

    local heartbeatMarkers = {
        0,
        0.04348,
        0.36863,
        1.05158,
        1.37572,
        sounds.heartbeat.TimeLength
    }

    local lowerTransparency = 0.2
    local higherTransparency = 0.8

    if toggle then
        RunService:BindToRenderStep("BloodUi", 200, function(delta: number)  
            local currentTimePosition = sounds.heartbeat.TimePosition
            for i = 1, #heartbeatMarkers - 1, 1 do
                if heartbeatMarkers[i] <= currentTimePosition and currentTimePosition < heartbeatMarkers[i + 1] then
                    local transparencyValue
                    local colorValue
                    if i % 2 == 0 then
                        transparencyValue = math.map(currentTimePosition, heartbeatMarkers[i], heartbeatMarkers[i + 1], lowerTransparency, higherTransparency)
                        local x = math.map(currentTimePosition, heartbeatMarkers[i], heartbeatMarkers[i + 1], 0, 255) 
                        colorValue = Color3.fromRGB(255, x, x)
                    else
                        transparencyValue = math.map(currentTimePosition, heartbeatMarkers[i], heartbeatMarkers[i + 1], higherTransparency, lowerTransparency)
                        local x = math.map(currentTimePosition, heartbeatMarkers[i], heartbeatMarkers[i + 1], 255, 0) 
                        colorValue = Color3.fromRGB(255, x, x)
                    end
                    bloodUi.GroupTransparency = transparencyValue
                    References.StatGuiManager.getCanvasGroup(statGuiObject).GroupColor3 = colorValue
                    --warn(i)
                    return
                end
            end
        end)
    else 
        RunService:UnbindFromRenderStep("BloodUi")
        local ti = TweenInfo.new(1)
        TweenService:Create(bloodUi, ti, {GroupTransparency = 1}):Play()
    end
end

function Health.initialize()

    -- Initial
    local savedHealthValue: number = References.humanoid.Health
    References.StatGuiManager.SetStatValue(statGuiObject, References.humanoid.Health/References.humanoid.MaxHealth)

    -- On change
    References.humanoid.HealthChanged:Connect(function(health: number)
        math.clamp(health, 0, math.huge)
        if savedHealthValue <= 0 then return end

        local healthProportion: number = math.round((health/References.humanoid.MaxHealth) * 100)/100

        --Heartbeat Sound manager
        updateHeartbeatSoundProperties(healthProportion)

        --Ear ringing sound manager
        updateEarRingingSoundProperties(healthProportion)

        savedHealthValue = health
        References.StatGuiManager.SetStatValue(statGuiObject, healthProportion)
    end)

    table.insert(
        connections,
        sounds.heartbeat:GetPropertyChangedSignal("Playing"):Connect(function(...: any)  
            warn(sounds.heartbeat.IsPlaying)
            toggleBloodGuiHeartbeatSync(sounds.heartbeat.IsPlaying)
        end)
    )

end

return Health