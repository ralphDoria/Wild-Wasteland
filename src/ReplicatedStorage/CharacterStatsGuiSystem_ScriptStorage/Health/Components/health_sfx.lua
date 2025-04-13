local References = require("../../Data/References")
local gameSG: SoundGroup = References.SoundService["0 - Master"]:FindFirstChild("Game", true)
local dyingReverb: ReverbSoundEffect = game:GetService("SoundService"):FindFirstChild("DyingReverb", true)

local health_sfx = {}

function health_sfx.tweenDyingReverbTo(value: number, transitionTime: number)
    if value == dyingReverb.WetLevel then return end

    if dyingReverb.WetLevel == -30 then
        dyingReverb.Enabled = true
    end

    local reverbTween = References.TweenService:Create(dyingReverb, TweenInfo.new(transitionTime), {WetLevel = value})

    if value == -30 then
        reverbTween.Completed:Once(function(a0: Enum.PlaybackState)  
            dyingReverb.Enabled = false
        end) 
    end

    reverbTween:Play()
end

function health_sfx.tweenGameAudioVolumeTo(value: number, transitionTime: number)
    if value == gameSG.Volume then return end
    local volumeTween = References.TweenService:Create(gameSG, TweenInfo.new(transitionTime), {Volume = value})
    volumeTween:Play()
end

return health_sfx