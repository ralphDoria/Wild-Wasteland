------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

------------------------------------------------------------------------<<<FUNCTION>>>
return function(soundObject : Sound, soundParent, delayCorrection : number)
    local soundClone = soundObject:Clone()
    if delayCorrection then
		soundClone.TimePosition = delayCorrection
	end
    if soundParent then    
        if typeof(soundParent) == "Vector3" then
            local x = Instance.new("Part")
            x.Anchored = true

            x.Transparency = 1

            x.CanCollide = false
            x.CanQuery = false
            x.Size = Vector3.new(0.1, 0.1, 0.1)
            x.Position = soundParent
            x.Parent = workspace
            soundClone.Parent = x
            soundClone:Play()
            --Debris:AddItem(x, soundClone.TimeLength)
        elseif soundParent:IsA("BasePart") then
            soundClone.Parent = soundParent
            soundClone:Play()
        else
            warn("soundParent is nil")
        end
    else
        SoundService:PlayLocalSound(soundClone)
    end
	Debris:AddItem(soundClone, soundClone.TimeLength)
end