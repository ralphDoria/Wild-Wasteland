local playSound = require(script.Parent:WaitForChild("PlaySoundUtil"))

local SOUND_EVENT = "Sound"
local RANDOM_SOUND_EVENT = "RandomSound"

--[[
use for footsteps
]]

local function bindSoundsToAnimationEvents(animation: AnimationTrack, SFX_part)
	animation:GetMarkerReachedSignal(SOUND_EVENT):Connect(function(param: string)
		local sound = SFX_part:FindFirstChild(param)
		if not sound then
            print("sound not found")
			return
		end
		playSound(sound, 0, SFX_part)
	end)
end

return bindSoundsToAnimationEvents
