local References = require("../Data/References")
local TweenService = game:GetService("TweenService")
local statGui: CanvasGroup = References.CharacterStatsGui.Frame.health
local statGuiObject = References.StatGuiManager.new(statGui, "Health", Color3.fromRGB(255, 0, 0))
local RunService = game:GetService("RunService")
local SoundUtility = require("../SharedComponents/SoundUtility")
local health_vfx = require("./Components/health_vfx")
local health_sfx = require("./Components/health_sfx")

--Sounds
local sounds: {[string]: Sound} = {
    earsRinging = References.debuffSounds.Health.EarsRinging,
    heartbeat = References.debuffSounds.Health.Heartbeat
}

local effectsOverlay = References.playerGui:WaitForChild("EffectsOverlay")
effectsOverlay.Enabled = true
local bloodUi: CanvasGroup = effectsOverlay.Blood

local connections = {}


local proportionMarkers = {
    startHeartbeat = 0.5, -- also when color correction starts
    startEarRinging = 0.2, -- also when reverb starts
    dead = 0
}

local baseHeartbeatSpeed = 1
local maxHeartbeatSpeed = 2

local function updateHeartbeatEffects(healthProportion: number)
    if healthProportion > proportionMarkers.startHeartbeat then
        SoundUtility.tweenSoundSpeed(sounds.heartbeat, baseHeartbeatSpeed, 1)
        SoundUtility.tweenSoundVolume(sounds.heartbeat, 0, 0.5)
    elseif healthProportion > proportionMarkers.dead then
        local heartbeatSpeed = math.clamp(math.map(healthProportion, proportionMarkers.startHeartbeat, proportionMarkers.dead, baseHeartbeatSpeed, maxHeartbeatSpeed), baseHeartbeatSpeed, maxHeartbeatSpeed)
        --print(heartbeatSpeed)
        SoundUtility.tweenSoundSpeed(sounds.heartbeat, heartbeatSpeed, 0.5)
        SoundUtility.tweenSoundVolume(sounds.heartbeat, 1, 0.5)
        health_vfx.tweenDyingColorCorrectionTo(
            math.clamp(math.map(healthProportion, proportionMarkers.startHeartbeat, proportionMarkers.dead, 0, -1), -1, 0), 
            0.5)
        health_sfx.tweenGameAudioVolumeTo(
            math.clamp(math.map(healthProportion, proportionMarkers.startHeartbeat, proportionMarkers.dead, 1, 0.2), 0.2, 1), 
            0.5)
    elseif healthProportion <= proportionMarkers.dead then
        local tween = SoundUtility.tweenSoundSpeed(sounds.heartbeat, 0.3, 3)
        tween.Completed:Once(function(a0: Enum.PlaybackState)
            SoundUtility.tweenSoundVolume(sounds.heartbeat, 0, 5)
        end)
    end
end

local function updateEarRingingSoundProperties(healthProportion: number)
    if healthProportion > proportionMarkers.startEarRinging then -- possible healthProportion values here: (0.2, inf)
        SoundUtility.tweenSoundVolume(sounds.earsRinging, 0, 0.5)
    elseif healthProportion > proportionMarkers.dead then -- possible healthProportion values here: (0, 0.2]
    SoundUtility.tweenSoundVolume(sounds.earsRinging, 0.5, 0.5)
        health_sfx.tweenDyingReverbTo(math.clamp(
            math.map(healthProportion, proportionMarkers.startEarRinging, proportionMarkers.dead, -30, 20), -30, 20), 
            0.5)    
    elseif healthProportion <= proportionMarkers.dead then -- possible healthProportion values here: (-inf, 0]
        SoundUtility.tweenSoundVolume(sounds.earsRinging, 0, 4)
    end
end

local Health = {}

local function toggleGuiHeartbeatSoundSync(toggle: boolean)

    local heartbeatMarkers = {
        0,
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
        health = math.clamp(health, 0, math.huge)
        if savedHealthValue <= 0 then return end

        local healthProportion: number = math.round((health/References.humanoid.MaxHealth) * 100)/100

        --Heartbeat Sound manager
        updateHeartbeatEffects(healthProportion)

        --Ear ringing sound manager
        updateEarRingingSoundProperties(healthProportion)

        savedHealthValue = health
        References.StatGuiManager.SetStatValue(statGuiObject, healthProportion)
    end)

    table.insert(
        connections,
        sounds.heartbeat:GetPropertyChangedSignal("Playing"):Connect(function(...: any)  
            toggleGuiHeartbeatSoundSync(sounds.heartbeat.IsPlaying)
        end)
    )

end

return Health