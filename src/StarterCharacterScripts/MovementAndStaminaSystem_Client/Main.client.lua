local config = require("./Modules/Config")
local MovementStateMachine = require("./Modules/MovementStateMachine")

error("this script is the old version")
------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local ACTION_SPRINT = "Sprint"
local ACTION_CROUCH = "Crouch"
local SPRINT_KEY = Enum.KeyCode.LeftShift
local CROUCH_KEY = Enum.KeyCode.C

------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game.Players.LocalPlayer
local humanoid = player.Character:WaitForChild("Humanoid")
local camera = workspace.CurrentCamera

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local rev_changeWalkSpeed = game:GetService("ReplicatedStorage").CharacterRemotes.ChangeWalkSpeed

local character = game:GetService("Players").LocalPlayer.Character or game:GetService("Players").LocalPlayer.CharacterAdded:Wait()
local humanoid = character.Humanoid
local animator : Animator = humanoid.Animator
local anims = {
	crouchIdle = ReplicatedStorage.CrouchAnimations.Idle,
	crouchWalk = ReplicatedStorage.CrouchAnimations.Walk
}
local crouchIdleTrack = animator:LoadAnimation(anims.crouchIdle)
local crouchWalkTrack = animator:LoadAnimation(anims.crouchWalk)

local crouching = false

local tweenInfo = TweenInfo.new(0.2)
local tweenCamOffsetDown = TweenService:Create(humanoid, tweenInfo, {CameraOffset = Vector3.new(0, -1.5, 0)})
local tweenCamOffsetUp = TweenService:Create(humanoid, tweenInfo, {CameraOffset = Vector3.new(0, 0, 0)})

local function setCrouchingState(set : boolean)
	if set == true then
		character:SetAttribute("Crouching", true)
		crouching = true
		crouchIdleTrack:Play()
		tweenCamOffsetUp:Pause()
		tweenCamOffsetDown:Play()
	else
		character:SetAttribute("Crouching", false)
		crouching = false
		crouchIdleTrack:Stop()
		crouchWalkTrack:Stop()
		tweenCamOffsetDown:Pause()
		tweenCamOffsetUp:Play()
	end
end

local function handleAction(actionName, inputState, _inputObject)
	if actionName == ACTION_SPRINT then
		if inputState == Enum.UserInputState.Begin then
			setCrouchingState(false)
			rev_changeWalkSpeed:FireServer(humanoid, true, 20)
			humanoid.Parent:SetAttribute("isSprinting", true)
		elseif inputState == Enum.UserInputState.End and UserInputService:IsKeyDown(CROUCH_KEY) then
			setCrouchingState(true)
			rev_changeWalkSpeed:FireServer(humanoid, true, 3)
			humanoid.Parent:SetAttribute("isSprinting", false)
		elseif inputState == Enum.UserInputState.End then
			setCrouchingState(false)
			rev_changeWalkSpeed:FireServer(humanoid, false)
			humanoid.Parent:SetAttribute("isSprinting", false)
		end
	elseif actionName == ACTION_CROUCH then
		if inputState == Enum.UserInputState.Begin then
			setCrouchingState(true)
			rev_changeWalkSpeed:FireServer(humanoid, true, 3)
			humanoid.Parent:SetAttribute("isSprinting", false)
		elseif inputState == Enum.UserInputState.End and UserInputService:IsKeyDown(SPRINT_KEY) then
			setCrouchingState(false)
			rev_changeWalkSpeed:FireServer(humanoid, true, 20)
			humanoid.Parent:SetAttribute("isSprinting", true)
		elseif inputState == Enum.UserInputState.End then
			setCrouchingState(false)
			rev_changeWalkSpeed:FireServer(humanoid, false)
			humanoid.Parent:SetAttribute("isSprinting", false)
		end
	end
end

humanoid.Running:Connect(function(speed)
	if crouching then
		if speed > 0 then
			local DirectionOfMovement = character.HumanoidRootPart.CFrame:VectorToObjectSpace( character.HumanoidRootPart.AssemblyLinearVelocity )
			DirectionOfMovement = Vector3.new( DirectionOfMovement.X / humanoid.WalkSpeed, 0, DirectionOfMovement.Z / humanoid.WalkSpeed )
			local newSpeed = if DirectionOfMovement.Z < 0.1 then crouchWalkTrack.Speed else -crouchWalkTrack.Speed
			crouchWalkTrack:Play(0.5)
			crouchWalkTrack:AdjustSpeed(newSpeed)
		else 
			crouchWalkTrack:Stop(0.5)
		end
	end
end)

ContextActionService:BindAction(ACTION_SPRINT, handleAction, true, SPRINT_KEY)
ContextActionService:BindAction(ACTION_CROUCH, handleAction, true, CROUCH_KEY)

local jumpCooldown = 1
local CharacterStatusGui = player.PlayerGui:WaitForChild("CharacterStatusGui")
local jumpIndicator : ImageLabel = CharacterStatusGui:FindFirstChild("jumpIndicator", true)

local function round(number)
    if math.floor(number) ~= number then
        return string.format("%.1f", number)
    end
end