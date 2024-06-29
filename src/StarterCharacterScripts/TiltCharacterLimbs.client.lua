--[[
    -author @dthecoolest
    -copy & pasted from https://devforum.roblox.com/t/bending-player-torso-on-an-r6-rig/1945245/3?u=niletheus
    -modified by @Niletheus
]]

--[[
        The only thing I modified from this script is organize the variables into tables (see the M6Ds & originC0 arrays). I need to actually
    understand how the M6Ds are being manipulated with CFrame to learn procedural animation.
        By the way, this is only client sided for now.
]]

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tiltAt = ReplicatedStorage:WaitForChild("tiltAt")

------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local torso = character:WaitForChild("Torso")
local head = character:WaitForChild("Head")
local hrp = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera

local M6Ds : Motor6D = {
    rightHip = torso:WaitForChild("Right Hip"),
    leftHip = torso:WaitForChild("Left Hip"),
	rightShoulder = torso:WaitForChild("Right Shoulder"),
	leftShoulder = torso:WaitForChild("Left Shoulder"),
    neck = torso:WaitForChild("Neck"),
    bodyAttachJoint = torso.BodyAttachJoint
}

--mapping function for 
--|
--|
--|
--V

local originC0 : CFrame = {} --this is so we know the default positions for each Motor6D
local originC0Holder = ReplicatedStorage:WaitForChild("originC0Holder")

for key, v in pairs(M6Ds) do --populating the originC0 table
    originC0[key] = originC0Holder:WaitForChild("Torso"):WaitForChild(M6Ds[key].Name).C0
end

M6Ds.neck.MaxVelocity = 1/3
------------------------------------------------------------------------<<<LOCAL VARIABLES>>>

------------------------------------------------------------------------<<<Motor6D Stuff>>>


------------------------------------------------------------------------<<<Run Service Loop>>>
--*understand the difference between different RunService Events
local timeAccumulated = 0
local remoteEventFireRate = 0.1

--trying to make the arms rotate relative to head position

--[[ scratch work
    targetCFrameOfRightArm = CFrame.new(head.Position) * CFrame.Angles(0, 0, theta) * CFrame.new(0, -1, 0)
    currentCFrameOfRightArm * offset = targetCFrameOfRightArm
    offset = currentCFrameOfRightArm:Inverse() * targetCFrameOfRightArm

    torso.CFrame * rightShoulder.C0 = rightArm.CFrame * rightShoulder.C1
    targetCFrameOfRightArm * torso.CFrame * rightShoulder.C0 = targetCFrameOfRightArm * rightArm.CFrame * rightShoulder.C1
    rightShoulder.C0 = 
]]
RunService.RenderStepped:Connect(function(dt)
    if timeAccumulated < remoteEventFireRate then
        timeAccumulated += dt
    else
        timeAccumulated = 0

        local theta = math.asin(camera.CFrame.LookVector.Y)

        --moved calculations to to client-sided
        local newCalculatedCFrames : CFrame = {
            neck = originC0.neck * CFrame.Angles(-theta, 0, 0),
            rightShoulder = originC0.rightShoulder  * CFrame.Angles(0, 0, theta),
            leftShoulder = originC0.leftShoulder * CFrame.Angles(0, 0, -theta), 
            bodyAttachJoint = originC0.bodyAttachJoint * CFrame.Angles(theta, 0, 0)
        }
        tiltAt:FireServer(newCalculatedCFrames, character:FindFirstChildOfClass("Tool"))
    end
end)

