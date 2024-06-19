local player = game.Players.LocalPlayer --Because of this line, this module must be required in a LocalScript, else there will be an error.
local humanoid = player.Character:WaitForChild("Humanoid")
local PlayerGui = player:WaitForChild("PlayerGui")
local CharacterStatusGui = PlayerGui:WaitForChild("CharacterStatusGui")

local UserInputService = game:GetService("UserInputService")

local SPRINT_KEY = Enum.KeyCode.LeftShift

local CharacterSpeedInfo = require(script.Parent.CharacterSpeedInfo)
local StaminaManager = require(script.Parent.StaminaManager)
local isMoving

local Sprint = {SPRINT_KEY = SPRINT_KEY}

function Sprint.sprintKeyDown()
	local isMoving = humanoid.MoveDirection.Magnitude > 0.01
	if not isMoving then return end
	if StaminaManager.getCurrentStamina()/StaminaManager.MAX_STAMINA < StaminaManager.MIN_REQUIRED_STAMINA/100 then 
        StaminaManager.indicateInsufficientStaminaForSprint()
        return 
    end
    local checkIfPlayerStopsMoving
    checkIfPlayerStopsMoving = humanoid.Running:Connect(function(speed)
        if speed <= 0 then
            checkIfPlayerStopsMoving:Disconnect()
            humanoid.WalkSpeed = CharacterSpeedInfo.walkSpeed
            StaminaManager.fillStaminaBar()
        end
    end)
    humanoid.WalkSpeed = CharacterSpeedInfo.sprintSpeed
    StaminaManager.drainStaminaBar()
end

function Sprint.sprintKeyUp()
    humanoid.WalkSpeed = CharacterSpeedInfo.walkSpeed
    StaminaManager.fillStaminaBar()
end

return Sprint