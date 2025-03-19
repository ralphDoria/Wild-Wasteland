------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

------------------------------------------------------------------------<<<FUNCTION>>>
local function playSound(soundObject : Sound, soundParent, delayCorrection : number)
    if delayCorrection then
        if delayCorrection >= 0 then
            soundObject.TimePosition = delayCorrection
        else
            task.delay(math.abs(delayCorrection), function()
                playSound(soundObject, soundParent, 0)
            end)
            return
        end
	end
    local soundClone = soundObject:Clone()
    local pitch : PitchShiftSoundEffect? = soundClone:FindFirstChildOfClass("PitchShiftSoundEffect")
    if pitch then
        pitch.Octave = math.random(90, 110)/100
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
        elseif soundParent:IsA("BasePart") or soundParent:IsA("MeshPart") or soundParent:IsA("GuiObject") then
            soundClone.Parent = soundParent
            soundClone:Play()
        else
            warn("soundParent is not of a valid type")
        end
    else
        SoundService:PlayLocalSound(soundClone)
    end
	Debris:AddItem(soundClone, soundClone.TimeLength)
end

return playSound