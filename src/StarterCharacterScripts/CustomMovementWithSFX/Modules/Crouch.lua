------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local CROUCH_KEY = Enum.KeyCode.C

------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game.Players.LocalPlayer --Because of this line, this module must be required in a LocalScript, else there will be an error.
local humanoid = player.Character:WaitForChild("Humanoid")

------------------------------------------------------------------------<<<MODULES>>>
local CharacterSpeedInfo = require(script.Parent.CharacterSpeedInfo)

------------------------------------------------------------------------<<<MODULE SCRIPT>>>
local Crouch = {CROUCH_KEY = CROUCH_KEY}

function Crouch.crouchKeyDown()
    humanoid.WalkSpeed = CharacterSpeedInfo.crouchSpeed
end

function Crouch.crouchKeyUp()
    humanoid.WalkSpeed = CharacterSpeedInfo.walkSpeed
end

return Crouch