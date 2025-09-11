local playSound = require(game:GetService("ReplicatedStorage").RojoManaged_RS.Utility.PlaySoundUtil)
local playRandomSoundFromSource = require(script.Parent.playRandomSoundFromSource)

local SOUND_EVENT = "Sound"
local RANDOM_SOUND_EVENT = "RandomSound"

local function bindSoundsToAnimationEvents(animation: AnimationTrack, sounds: Folder, bodyAttach: Part)
	animation:GetMarkerReachedSignal(SOUND_EVENT):Connect(function(param: string)
		local sound = sounds:FindFirstChild(param)
		if not sound then
			return
		end
		-- playSoundFromSource(sound, target)
		local delayCorrection = sound:GetAttribute("DelayCorrection")
		playSound(sound, bodyAttach, if delayCorrection then delayCorrection else nil)
		
	end)

	-- For repetitive sounds like shooting, we'll play a random sound variation from a selection, rather than playing the same sound over and over.
	animation:GetMarkerReachedSignal(RANDOM_SOUND_EVENT):Connect(function(param: string)
		local folder = sounds:FindFirstChild(param)
		if not folder then
			return
		end
		playRandomSoundFromSource(folder, bodyAttach)
	end)
end

return bindSoundsToAnimationEvents
