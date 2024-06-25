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
    waist = hrp:WaitForChild("RootJoint")
}

--mapping function for 
--|
--|
--|
--V

local originC0 : CFrame = {} --this is so we know the default positions for each Motor6D

for key, v in pairs(M6Ds) do --populating the originC0 table
    originC0[key] = M6Ds[key].C0
end

M6Ds.neck.MaxVelocity = 1/3
------------------------------------------------------------------------<<<LOCAL VARIABLES>>>

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tiltAt = ReplicatedStorage:WaitForChild("tiltAt")
------------------------------------------------------------------------<<<Run Service Loop>>>
--*understand the difference between different RunService Events
local timeAccumulated = 0
local remoteEventFireRate = 0

RunService.RenderStepped:Connect(function(dt)
    if timeAccumulated < remoteEventFireRate then
        timeAccumulated += dt
    else
        timeAccumulated = 0
        tiltAt:FireServer(math.asin(camera.CFrame.LookVector.Y))
    end
end)
