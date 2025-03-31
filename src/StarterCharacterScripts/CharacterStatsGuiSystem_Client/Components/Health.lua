local References = require("./References")
References.update()
local TweenService = game:GetService("TweenService")
local statGui: CanvasGroup = References.CharacterStatsGui.Frame.health
local statGuiObject = References.StatGuiManager.new(statGui, "Health", Color3.fromRGB(255, 0, 0))

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

local function tweenHeartbeatSpeedTo(value: number)
    if sounds.heartbeat.PlaybackSpeed == value then return end
    value = math.clamp(value, 0, 2)
    local ti = TweenInfo.new(1)
    local speedTween = TweenService:Create(sounds.heartbeat, ti, {PlaybackSpeed = value})
    local pitchTween = TweenService:Create(heartbeatPitch, ti, {Octave = 1/value})
    speedTween:Play()
    pitchTween:Play()
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
    [1] = 0.5, -- heartbeat can be heard. Starts at playback speed = 1 and maxes out at 2 when proportion reaches 0.1
    [2] = 0.2, -- ear ringing starts
    [3] = 0.1, -- heartbeat is at its fastest, anything lower than this an the heart beat will slow to playbackspeed = 0.5
    [4] = 0 -- last heartbeat is heard, ear ringing fades to 0
}

local function updateHeartbeatSoundProperties(healthProportion: number)
    if healthProportion > proportionMarkers[1] then -- possible healthProportion values here: (0.5, inf)
            tweenSoundVolume(sounds.heartbeat, 0, 0.5)
        elseif healthProportion > proportionMarkers[3] then -- possible healthProportion values here: (0.1, 0.5]
            local heartbeatSpeed = math.clamp(
                1 + (1 - (healthProportion - proportionMarkers[3])/(proportionMarkers[1]-proportionMarkers[3])), -- Makes heartbeat faster as healthProportion decreases in this interval
                1, 
                2)
            --warn("Hearbeat Speed: ", heartbeatSpeed)
            tweenHeartbeatSpeedTo(heartbeatSpeed)
            tweenSoundVolume(sounds.heartbeat, 1, 0.5)
        elseif healthProportion > proportionMarkers[4] then -- possible healthProportion values here: (0, 0.1]
            local heartbeatSpeed = math.lerp(
                0.2, 
                0.5, 
                (healthProportion - proportionMarkers[4])/(proportionMarkers[3]-proportionMarkers[4])) -- Makes heartbeat slower as healthProportion decreases in this interval
            --warn("Hearbeat Speed: ", heartbeatSpeed)
            tweenHeartbeatSpeedTo(heartbeatSpeed)
            tweenSoundVolume(sounds.heartbeat, 2, 0.5)
        else -- possible healthProportion values here: (-inf, 0]
            --final heartbeat
            if sounds.heartbeat.IsPlaying then
                sounds.heartbeat.DidLoop:Once(function(a0: string, a1: number)
                    sounds.heartbeat:Stop()
                end)
            end
        end
end

local function updateEarRingingSoundProperties(healthProportion: number)
    if healthProportion > proportionMarkers[2] then -- possible healthProportion values here: (0.2, inf)
        tweenSoundVolume(sounds.earsRinging, 0, 0.5)
    elseif healthProportion <= proportionMarkers[2] and healthProportion > proportionMarkers[4] then -- possible healthProportion values here: (0, 0.2]
        tweenSoundVolume(sounds.earsRinging, 0.5, 0.5)

    elseif healthProportion <= proportionMarkers[4] then -- possible healthProportion values here: (-inf, 0]
        tweenSoundVolume(sounds.earsRinging, 0, 4)
    end

    if sounds.earsRinging.IsPlaying then
        tweenDyingReverbTo(
            math.clamp(
                math.lerp(-30, 20, 1 - (healthProportion - proportionMarkers[4])/(proportionMarkers[2]-proportionMarkers[4])),
                -30,
                20), 
            0.5)
        tweenDyingColorCorrectionTo(
            math.clamp(
                math.lerp(-1, 0, (healthProportion - proportionMarkers[4])/(proportionMarkers[2]-proportionMarkers[4])),
                -1,
                0),
            0.5)
        tweenGameAudioVolumeTo(
            math.clamp(
                math.lerp(0.1, 1, (healthProportion - proportionMarkers[4])/(proportionMarkers[2]-proportionMarkers[4])),
                0.1,
                1),
            0.5)
    end
end

local Health = {}

sounds.heartbeat:GetPropertyChangedSignal("TimePosition"):Connect(function()  
        print(sounds.heartbeat.TimePosition)
end)

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
end

return Health