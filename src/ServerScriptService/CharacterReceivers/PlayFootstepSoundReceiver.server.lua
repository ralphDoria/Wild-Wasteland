local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_footstepSFX = ReplicatedStorage.CharacterRemotes.FootstepSFX
local playSound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

rev_footstepSFX.OnServerEvent:Connect(function(player : Player, soundToPlay : Sound, soundParent)
	playSound(soundToPlay, soundParent)
end)