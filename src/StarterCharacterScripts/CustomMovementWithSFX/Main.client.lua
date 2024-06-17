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

local JUMP_STAMINA_COST = StaminaManager.MAX_STAMINA * 0.3
local SLIDE_STAMINA_COST

humanoid.Jumping:Connect(function()
	if StaminaManager.getCurrentStamina() > JUMP_STAMINA_COST then
		print("checkoint 90")
		humanoid.JumpHeight = 4
		StaminaManager.updateStaminaBar(StaminaManager.getCurrentStamina() - JUMP_STAMINA_COST/2) --Jump stamina cost is divided by 2 here because the humanoid.Jumping event fires twice (once for when the jump starts and once for when the jump ends), but I only want to apply the JUMP_STAMINA_COST once per jump.
		StaminaManager.fillStaminaBar()
	else
		print("checkpoint 91")
		humanoid.JumpHeight = 0
	end
end)

humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
	AnimationManager.crouchAnimHandler(humanoid.WalkSpeed)
end)

print(Sprint.sprintSpeed) --testing to see if field variable works

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Sprint.SPRINT_KEY then
		Sprint.sprintKeyDown()
	elseif input.KeyCode == Crouch.CROUCH_KEY then
        Crouch.crouchKeyDown()
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

