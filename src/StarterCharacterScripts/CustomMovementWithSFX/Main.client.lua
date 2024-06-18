--[[
    *A separate script will deal with updating the Stamina HUD Gui based on a couple things

    -w/ SFX means this script will also handle footstep sounds

    -play animation based on player speed

    !!!!
    this script is currently hecka buggy & needs to be fixed later
]]

--Sprint

--Crouch

local player = game.Players.LocalPlayer
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local animator = humanoid:WaitForChild("Animator")
local UIS = game:GetService("UserInputService")
local PlayerGui = player:WaitForChild("PlayerGui")

--Modules
local Sprint = require(script.Parent.Modules:WaitForChild("Sprint"))
local Crouch = require(script.Parent.Modules:WaitForChild("Crouch"))
local StaminaManager = require(script.Parent.Modules:WaitForChild("StaminaManager"))
local AnimationManager = require(script.Parent.Modules:WaitForChild("AnimationManager"))

--This handles the animations. It plays/stops certain animation tracks when the humanoid is moving at a certain speed.
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

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Sprint.SPRINT_KEY then
		Sprint.sprintKeyDown()
	elseif input.KeyCode == Crouch.CROUCH_KEY then
        Crouch.crouchKeyDown()
	elseif input.KeyCode == Enum.KeyCode.Space then
		if humanoid:GetStateEnabled(Enum.HumanoidStateType.Jumping) == false then
			StaminaManager.indicateInsufficientStaminaForJump()
		end
	end
end)
UIS.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Sprint.SPRINT_KEY then
		Sprint.sprintKeyUp()
	elseif input.KeyCode == Crouch.CROUCH_KEY then
        Crouch.crouchKeyUp()
	end
end)
--end of sprint code; what I learned: printing is vital to catch logic errors, don't rely on system errors. It's good practice !!

