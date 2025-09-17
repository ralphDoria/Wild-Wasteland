local playSound = require(game:GetService("ReplicatedStorage").RojoManaged_RS.Utility.PlaySoundUtil)
local playRandomSoundFromSource = require(script.Parent.playRandomSoundFromSource)


local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolInfo = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Data.ToolInfo

local SOUND_EVENT = "Sound"
local RANDOM_SOUND_EVENT = "RandomSound"

local function bindSoundsToAnimationEvents(animation: AnimationTrack, sounds: {[string]: any}, bodyAttach: Part)
	animation:GetMarkerReachedSignal(SOUND_EVENT):Connect(function(param: string)
		local sound = sounds[param]
		if not sound then
			return
		end
		-- playSoundFromSource(sound, target)
		local delayCorrection = sound:GetAttribute("DelayCorrection")
		playSound(sound, bodyAttach, if delayCorrection then delayCorrection else nil)
		
	end)

	-- For repetitive sounds like shooting, we'll play a random sound variation from a selection, rather than playing the same sound over and over.
	animation:GetMarkerReachedSignal(RANDOM_SOUND_EVENT):Connect(function(param: string)
		local soundsArray = sounds[param]
		if not soundsArray then
			return
		end
		playRandomSoundFromSource(soundsArray, bodyAttach)
	end)
end

return bindSoundsToAnimationEvents
