------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local torso = character:WaitForChild("torso")
local head = character:WaitForChild("Head")
local hrp = character:WaitForChild("HumanoidRootPart")
local mouse = player:GetMouse()

local M6Ds : Motor6D = {
    rightHip = torso:WaitForChild("Right Hip"),
    leftHip = torso:WaitForChild("Left Hip"),
    neck = torso:WaitForChild("Neck"),
    waist = hrp:WaitForChild("RootJoint")
}

--mapping function for 
--|
--|
--|
--V

local originC0 = {} --this is so we know the default positions for each Motor6D

for key, v in pairs(M6Ds) do --populating the originC0 table
    originC0[key] = M6Ds[key].C0
end

M6Ds.neck.MaxVelocity = 1/3
------------------------------------------------------------------------<<<LOCAL VARIABLES>>>

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local RunService = game:GetService("RunService")

--*understand the difference between different RunService Events
RunService.RenderStepped:Connect(function(dt)
    local point : Vector3 = mouse.Hit.Position
    
    
end)
