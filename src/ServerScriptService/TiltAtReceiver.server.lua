local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tiltAt = ReplicatedStorage:WaitForChild("tiltAt")
local TweenService = game:GetService("TweenService")

local originC0 = {
    neck = ReplicatedStorage.originC0Holder.Torso.Neck.C0,
    rightShoulder = ReplicatedStorage.originC0Holder.Torso["Right Shoulder"].C0,
    leftShoulder = ReplicatedStorage.originC0Holder.Torso["Left Shoulder"].C0
}

tiltAt.OnServerEvent:Connect(function(player, xRotation)
	local torso = player.Character.Torso
    local neck : Motor6D = torso.Neck
	local rightShoulder = torso["Right Shoulder"]
	local leftShoulder = torso["Left Shoulder"]

	--idk what I'm doing
	local tool = player.Character:FindFirstChildOfClass("Tool")
	if tool then
		local bodyAttachJoint = torso.BodyAttachJoint
		local bodyAttachJointOriginC0 = bodyAttachJoint.C0
		bodyAttachJoint.C0 = bodyAttachJointOriginC0 * CFrame.Angles(-xRotation, 0, 0)
	end

	local targetC0 = originC0.neck * CFrame.Angles(-xRotation, 0, 0)
	neck.C0 = targetC0
	rightShoulder.C0 = originC0.rightShoulder * CFrame.Angles(0, 0, xRotation)
	leftShoulder.C0 = originC0.leftShoulder * CFrame.Angles(0, 0, -xRotation)
end)
