local player = game.Players.LocalPlayer --Because of this line, this module must be required in a LocalScript, else there will be an error.
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local PlayerGui = player:WaitForChild("PlayerGui")
local CharacterStatusGui = PlayerGui:WaitForChild("CharacterStatusGui")

local SPRINT_KEY = Enum.KeyCode.LeftShift

local CharacterSpeedInfo = require(script.Parent.CharacterSpeedInfo)
local StaminaManager = require(script.Parent.StaminaManager)
local isMoving

local Sprint = {SPRINT_KEY = SPRINT_KEY}

function Sprint.sprintKeyDown()
	local isMoving = character.PrimaryPart.AssemblyLinearVelocity.Magnitude > 0.01
	if not isMoving then return end
	if not isMoving or StaminaManager.getCurrentStamina()/StaminaManager.MAX_STAMINA < StaminaManager.MIN_REQUIRED_STAMINA/100 then return end
    humanoid.WalkSpeed = CharacterSpeedInfo.sprintSpeed
    StaminaManager.drainStaminaBar()
end

function Sprint.sprintKeyUp()
    humanoid.WalkSpeed = CharacterSpeedInfo.walkSpeed
    StaminaManager.fillStaminaBar()
end

return Sprint