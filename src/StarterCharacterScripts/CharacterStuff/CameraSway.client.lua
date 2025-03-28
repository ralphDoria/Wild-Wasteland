local CONSTANTS = {
    SPRINT_SPEED = 20,
    WALK_SPEED = game:GetService("StarterPlayer").CharacterWalkSpeed,
    CROUCH_SPEED = 3,
    CROUCH_CAMERA_OFFSET = Vector3.new(0, -1.5, 0)
}

--Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

-- Variables
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local Camera = workspace.CurrentCamera
local Turn = 0

-- Functions
local Lerp = function(a, b, t)
	return a + (b - a) * t
end;

-- Main

local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()

local function updateCameraSway(deltaTime)
    local magnitude = 4

    local MouseDelta = UserInputService:GetMouseDelta()
	Turn = Lerp(Turn, math.clamp(MouseDelta.X, -magnitude, magnitude), (15 * deltaTime))
	Camera.CFrame = Camera.CFrame * CFrame.Angles(0, 0, math.rad(Turn))
end

local function updateViewBobbing()
    local currentTime = tick()
    local moveSpeed = character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude  
    
    local baseSpeed = math.pi --half circle (bob from one side to the other in one oscillation)
    local baseMagnitude = 0.25

    local scale

    if moveSpeed > CONSTANTS.SPRINT_SPEED - 1 then
        scale = (CONSTANTS.SPRINT_SPEED/ CONSTANTS.WALK_SPEED)
    elseif moveSpeed > CONSTANTS.WALK_SPEED - 1 then
        scale = (CONSTANTS.WALK_SPEED / CONSTANTS.WALK_SPEED)
    elseif moveSpeed > 0.1 then
        scale = (CONSTANTS.CROUCH_SPEED / CONSTANTS.WALK_SPEED)
    else
        scale = 0
    end
    local bobbleX = math.cos(currentTime * (baseSpeed * scale)) * (baseMagnitude * scale)
    local bobbleY = (if character:GetAttribute("Crouching") then CONSTANTS.CROUCH_CAMERA_OFFSET.Y else 0) 
        + math.abs(math.sin(currentTime * (baseSpeed * scale)) * (baseMagnitude * scale))
    local bobble = Vector3.new(bobbleX,  bobbleY - if character:GetAttribute("Crouch") == true then 1.5 else 0, 0)

    character.Humanoid.CameraOffset = character.Humanoid.CameraOffset:Lerp(bobble, 0.25)
end

RunService:BindToRenderStep("CameraSway", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    updateCameraSway(deltaTime)
    updateViewBobbing()
end)