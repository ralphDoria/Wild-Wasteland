local TweenService = game:GetService("TweenService")

local SoundUtility = {}

function SoundUtility.tweenSoundSpeed(sound: Sound, value: number, transitionTime: number): Tween?
    if sound.PlaybackSpeed == value then return end
    local pitchShiftObject = sound:FindFirstChildOfClass("PitchShiftSoundEffect")
    assert(pitchShiftObject ~= nil, sound.Name .. " needs a PitchShiftSoundEffect child.")
    value = math.clamp(value, 0, 2)
    local ti = TweenInfo.new(transitionTime, Enum.EasingStyle.Linear)
    local speedTween = TweenService:Create(sound, ti, {PlaybackSpeed = value})
    local pitchTween = TweenService:Create(pitchShiftObject, ti, {Octave = 1/value})
    speedTween:Play()
    pitchTween:Play()
    return speedTween
end

function SoundUtility.tweenSoundVolume(sound: Sound, newVolume: number, transitionTime: number)
    if newVolume == sound.Volume then  return end

    if not sound.IsPlaying and newVolume ~= 0 then
        -- print("playing", sound.Name)
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

return SoundUtility