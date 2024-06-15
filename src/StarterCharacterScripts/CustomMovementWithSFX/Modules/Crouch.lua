local CROUCH_KEY = Enum.KeyCode.C

local player = game.Players.LocalPlayer --Because of this line, this module must be required in a LocalScript, else there will be an error.
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")

local defaultSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed
local crouchSpeed = 3

local Crouch = {CROUCH_KEY = CROUCH_KEY}

function Crouch.crouchKeyDown()
    humanoid.WalkSpeed = crouchSpeed
end

function Crouch.crouchKeyUp()
    humanoid.WalkSpeed = defaultSpeed
end

return Crouch