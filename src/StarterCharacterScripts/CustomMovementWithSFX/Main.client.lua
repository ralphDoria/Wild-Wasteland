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
local AnimationManager = require(script.Parent.Modules:WaitForChild("AnimationManager"))

--This handles the animations. It plays/stops certain animation tracks when the humanoid is moving at a certain speed.
humanoid.Running:Connect(function(speed)
    AnimationManager.playAnimationBasedOnSpeed(speed)
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

