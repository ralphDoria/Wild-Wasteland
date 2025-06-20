local SoundService = game:GetService("SoundService")
local openSound : Sound = SoundService.SoundStorage.Game.LootContainers.openSound
local closeSound : Sound = SoundService.SoundStorage.Game.LootContainers.closeSound
local playSound = require(game:GetService("ReplicatedStorage"):FindFirstChild("PlaySoundUtil", true))

local SingleHingeLootable = {}

function SingleHingeLootable.onOpen_server(hingeConstraint: HingeConstraint)
    hingeConstraint.TargetAngle = -60
    playSound(openSound, hingeConstraint.Parent, 1.1)
end

function SingleHingeLootable.onClose_server(hingeConstraint: HingeConstraint)
    hingeConstraint.TargetAngle = 0
    playSound(closeSound, hingeConstraint.Parent, 0.5)
end

return SingleHingeLootable