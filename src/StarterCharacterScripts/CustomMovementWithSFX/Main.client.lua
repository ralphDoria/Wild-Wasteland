--[[
]]
------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local ACTION_SPRINT = "Sprint"
local ACTION_CROUCH = "Crouch"

------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game.Players.LocalPlayer
local humanoid = player.Character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local rev_sprint = ReplicatedStorage:WaitForChild("CharacterRemotes"):WaitForChild("Sprint")


local function handleAction(actionName, inputState, _inputObject)
	if actionName == ACTION_SPRINT then
		if inputState == Enum.UserInputState.Begin then
			camera.FieldOfView = 75
			rev_sprint:FireServer(humanoid, true)
		elseif inputState == Enum.UserInputState.End then
			camera.FieldOfView = 70
			rev_sprint:FireServer(humanoid, false)
		end
	end
end

ContextActionService:BindAction(ACTION_SPRINT, handleAction, true, Enum.KeyCode.LeftShift)

local jumpCooldown = 1
local CharacterStatusGui = player.PlayerGui:WaitForChild("CharacterStatusGui")
local jumpIndicator : ImageLabel = CharacterStatusGui:FindFirstChild("jumpIndicator", true)

local function round(number)
    if math.floor(number) ~= number then
        return string.format("%.1f", number)
    end
end

humanoid.Jumping:Connect(function(starting)
	jumpIndicator.ImageTransparency = 0.5
	jumpIndicator.cooldownLabel.Text = tostring(jumpCooldown)
	jumpIndicator.cooldownLabel.Visible = true
	if starting then
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		local currentCooldownTime = jumpCooldown
		while currentCooldownTime >= 0 do
			currentCooldownTime -= task.wait()
			jumpIndicator.cooldownLabel.Text = round(currentCooldownTime)
		end
		jumpIndicator.ImageTransparency = 0
		jumpIndicator.cooldownLabel.Visible = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	end
end)

--[[<<<<<<<<<<<<<<<<<<<<<<<< OLD CUSTOM MOVEMENT CODE >>>>>>>>>>>>>>>>>>>>>>>>>>>

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
]]