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

------------------------------------------------------------------------<<<Run Service Loop>>>
--*understand the difference between different RunService Events
RunService.RenderStepped:Connect(function(dt)
    local CameraCFrame = camera.CFrame

	if character:FindFirstChild("Torso") and character:FindFirstChild("Head") then --Player could die due to void and these parts get deleted
		local TorsoLookVector = torso.CFrame.lookVector
		local HeadPosition = head.CFrame.p

		if M6Ds.neck and M6Ds.waist then
			if camera.CameraSubject:IsDescendantOf(character) or camera.CameraSubject:IsDescendantOf(player) then
				local point : Vector3 = mouse.Hit.Position

				local Distance = (head.CFrame.p - point).magnitude
				local Difference = head.CFrame.Y - point.Y
				
				
				local goalNeckCFrame = CFrame.Angles(-(math.atan(Difference / Distance) * 0.5), (((HeadPosition - point).Unit):Cross(TorsoLookVector)).Y * 1, 0)
				M6Ds.neck.C0 = M6Ds.neck.C0:lerp(goalNeckCFrame*originC0.neck, 0.5 / 2).Rotation + originC0.neck.Position
				
				local xAxisWaistRotation = -(math.atan(Difference / Distance) * 0.5)
				local yAxisWaistRotation = (((HeadPosition - point).Unit):Cross(TorsoLookVector)).Y * 0.5
				local rotationWaistCFrame = CFrame.Angles(xAxisWaistRotation, yAxisWaistRotation, 0)
				local goalWaistCFrame = rotationWaistCFrame*originC0.waist
				M6Ds.waist.C0 = M6Ds.waist.C0:lerp(goalWaistCFrame, 0.5 / 2).Rotation + originC0.waist.Position
				
				
				local currentLegCounterCFrame = M6Ds.waist.C0*originC0.waist:Inverse()

				local legsCounterCFrame = currentLegCounterCFrame:Inverse()
				
				M6Ds.rightHip.C0 =  legsCounterCFrame*originC0.rightHip
				M6Ds.leftHip.C0 = legsCounterCFrame*originC0.leftHip
			end
		end
	end	
end)
