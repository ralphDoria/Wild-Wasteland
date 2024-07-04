------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

------------------------------------------------------------------------<<<FUNCTION>>>
return function(soundObject : Sound, soundParent : BasePart, delayCorrection : number)
    local soundClone = soundObject:Clone()
    if delayCorrection then
		soundClone.TimePosition = delayCorrection
	end
    if soundParent then
        soundClone.Parent = soundParent
	    soundClone:Play()
    else
        SoundService:PlayLocalSound(soundClone)
    end
	Debris:AddItem(soundClone, soundClone.TimeLength)
end