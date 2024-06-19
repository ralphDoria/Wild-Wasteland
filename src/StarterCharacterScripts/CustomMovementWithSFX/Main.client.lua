--[[
    *A separate script will deal with updating the Stamina HUD Gui based on a couple things

    -w/ SFX means this script will also handle footstep sounds

    -play animation based on player speed

    !!!!
    this script is currently hecka buggy & needs to be fixed later
]]
------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local ACTION_SPRINT = "Sprint"
local ACTION_CROUCH = "Crouch"

------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game.Players.LocalPlayer
local humanoid = player.Character:WaitForChild("Humanoid")

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

------------------------------------------------------------------------<<<MODULES>>>
local Sprint = require(script.Parent.Modules:WaitForChild("Sprint"))
local Crouch = require(script.Parent.Modules:WaitForChild("Crouch"))
local StaminaManager = require(script.Parent.Modules:WaitForChild("StaminaManager"))
local AnimationManager = require(script.Parent.Modules:WaitForChild("AnimationManager"))

------------------------------------------------------------------------<<<ANIMATIONS>>>
humanoid.Running:Connect(function(speed)
    AnimationManager.sprintAnimHandler(speed)
end)

humanoid.Jumping:Connect(function(starting)
	if starting then
		local staminaAfterJump = StaminaManager.getCurrentStamina() - StaminaManager.JUMP_STAMINA_COST
		StaminaManager.updateStaminaBar(staminaAfterJump)
		if staminaAfterJump < StaminaManager.JUMP_STAMINA_COST then
			-- This will only take effect for the NEXT jump so you need to disable jumping a bit earlier
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
		StaminaManager.fillStaminaBar()
	end
end)

humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	AnimationManager.crouchAnimHandler(humanoid.WalkSpeed)
end)

------------------------------------------------------------------------<<<USER INPUT>>>
local function handleAction(actionName : String, inputState, _inputObject)
	if actionName == ACTION_SPRINT then
		if inputState == Enum.UserInputState.Begin then
			Sprint.sprintKeyDown()
		end
		if inputState == Enum.UserInputState.End then
			Sprint.sprintKeyUp()
		end
	end

	if actionName == ACTION_CROUCH then
		if inputState == Enum.UserInputState.Begin then
			Crouch.crouchKeyDown()
		end
		if inputState == Enum.UserInputState.End then
			Crouch.crouchKeyUp()
		end
	end
end

ContextActionService:BindAction(ACTION_SPRINT, handleAction, true, Enum.KeyCode.LeftShift)
ContextActionService:BindAction(ACTION_CROUCH, handleAction, true, Enum.KeyCode.C)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.Space and humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false then
		StaminaManager.indicateInsufficientStaminaForJump()
	end
end)