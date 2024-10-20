local TweenService = game:GetService("TweenService")

local SoundUtil = {}

function SoundUtil.toggleMuffle(equalizer : EqualizerSoundEffect, toggle : boolean, transitionTime : number)
	if not equalizer.Enabled then 
        equalizer.Enabled = true 
    end

	local ti : TweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Linear)
	if toggle then
		TweenService:Create(equalizer, ti, {HighGain = -80}):Play()
		TweenService:Create(equalizer, ti, {MidGain = -80}):Play()
		TweenService:Create(equalizer, ti, {LowGain = 10}):Play()
	else
		TweenService:Create(equalizer, ti, {HighGain = 0}):Play()
		TweenService:Create(equalizer, ti, {MidGain = 0}):Play()
		TweenService:Create(equalizer, ti, {LowGain = 0}):Play()
	end
end

function SoundUtil.pitchDown(pitch : PitchShiftSoundEffect, time : number)
	pitch.Enabled = true
	local ti = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local targetPitch = 0.5
	if pitch.Octave == targetPitch then
		warn("effect is already pitched down")
	end
	local tween = TweenService:Create(pitch, ti, {Octave = targetPitch})
	tween:Play()
	return tween
end

function SoundUtil.pitchUp(pitch : PitchShiftSoundEffect, time : number)
	pitch.Enabled = true
	local ti = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local targetPitch = 1
	if pitch.Octave == targetPitch then
		warn("effect is already pitched up")
	end
	local tween = TweenService:Create(pitch, ti, {Octave = targetPitch})
	tween:Play()
	return tween
end

function SoundUtil.fadeVolume(sound : Sound, targetVolume : number, time : number)
	if targetVolume == sound.Volume then
		warn("Sound's volume is already at target volume")
	end
	local tween = TweenService:Create(sound, TweenInfo.new(time, Enum.EasingStyle.Linear), {Volume = targetVolume})
	tween:Play()
	return tween
end

function SoundUtil.trackSwitchEffect(pitch : PitchShiftSoundEffect, from : Sound, to : Sound)
	if not pitch.Enabled then pitch.Enabled = true end
	local tweenTime = 0.2
	local tween2 = TweenService:Create(pitch, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Octave = 0.25})
	local tween1 = TweenService:Create(pitch, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Octave = 1.5})
	local tween3 = TweenService:Create(pitch, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Octave = 1})
	tween1.Completed:Once(function()
		to:Play()
		task.wait(tweenTime)
		tween2:Play()
	end)
	tween2.Completed:Once(function()
		from:Stop()
		task.wait(tweenTime)
		tween3:Play()
	end)
	tween1:Play()
end

return SoundUtil