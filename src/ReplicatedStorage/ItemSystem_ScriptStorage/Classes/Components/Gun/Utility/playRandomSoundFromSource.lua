local playSound = require(game:GetService("ReplicatedStorage").RojoManaged_RS.Utility.PlaySoundUtil)

local random = Random.new()

local function playRandomSoundFromSource(soundTemplates: {Sound}, soundParent: Instance)
	local sound = soundTemplates[random:NextInteger(1, #soundTemplates)]
	local delayCorrection = sound:GetAttribute("DelayCorrection")
	playSound(sound, soundParent, if delayCorrection then delayCorrection else nil)
end

return playRandomSoundFromSource
