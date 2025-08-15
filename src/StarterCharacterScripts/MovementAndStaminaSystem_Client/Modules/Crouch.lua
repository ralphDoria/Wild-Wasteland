local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character.Humanoid
local animator: Animator = humanoid:FindFirstChildOfClass("Animator") :: Animator
local TweenService = game:GetService("TweenService")
local Config = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.Data.Config)
local MovementDirectionMonitor = require("./MovementDirectionMonitor")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementAndStaminaSystem_Storage = ReplicatedStorage.MovementAndStaminaSystem_Storage
local remotes: {[string]: RemoteEvent} = {
    ChangeHumanoidWalkSpeed = MovementAndStaminaSystem_Storage.Remotes.ChangeHumanoidWalkSpeed
}
local crouchAnimTrack = {
	idle = animator:LoadAnimation(MovementAndStaminaSystem_Storage.Anims.crouchIdle),
	walk = animator:LoadAnimation(MovementAndStaminaSystem_Storage.Anims.crouchWalk)
}
local tweenInfo = TweenInfo.new(0.2)
local camOffsetTween = {
    down = TweenService:Create(humanoid, tweenInfo, {CameraOffset = Vector3.new(0, -1.5, 0)}),
    up = TweenService:Create(humanoid, tweenInfo, {CameraOffset = Vector3.new(0, 0, 0)})
}
local connections: {RBXScriptConnection} = {}

local Crouch = {
    active = false
}

local function crouchWalkIfMoving(speed: number)
    if math.floor(speed) == 0 then
        crouchAnimTrack.walk:Stop()
    else
        crouchAnimTrack.walk:Play()
    end
end

local function updateCrouchWalkSpeed()
    local direction: MovementDirectionMonitor.zMovementDirection = MovementDirectionMonitor.getZDirectionOfMovement()
    if direction == "Forward" then
        crouchAnimTrack.walk:AdjustSpeed(1)
    elseif direction == "Backward" then
        crouchAnimTrack.walk:AdjustSpeed(-1)
    end
end

function Crouch.activate()
    if character and character.Parent ~= nil then
        crouchAnimTrack.idle:Play()
        camOffsetTween.down:Play()
        remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Crouch"])

        -- Initial check
        crouchWalkIfMoving(character.HumanoidRootPart.AssemblyLinearVelocity.Magnitude)
        updateCrouchWalkSpeed()

        -- When speed changes
        table.insert(
            connections,
            humanoid.Running:Connect(function(speed: number)  
                crouchWalkIfMoving(speed)
            end)
        )

        -- When zMovementDirection changes
        table.insert(
            connections,
            MovementDirectionMonitor.zMovementDirectionChanged:Connect(function()  
                updateCrouchWalkSpeed()
            end)
        )
    end

    Crouch.active = true
    character:SetAttribute("Crouch", true)
end

function Crouch.deactivate()
    if connections then
        for _, v in connections do
            v:Disconnect()
            v = nil
        end
    end
    for _, v in crouchAnimTrack do
        v:Stop()
    end
    camOffsetTween.up:Play()
    remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Default"])

    Crouch.active = false
    character:SetAttribute("Crouch", false)
end

return Crouch