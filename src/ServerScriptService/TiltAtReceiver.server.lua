local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tiltAt = ReplicatedStorage:WaitForChild("tiltAt")
local TweenService = game:GetService("TweenService")

local originC0 = {
    neck = ReplicatedStorage.originC0Holder.Torso.Neck.C0,
    rightShoulder = ReplicatedStorage.originC0Holder.Torso["Right Shoulder"].C0,
    leftShoulder = ReplicatedStorage.originC0Holder.Torso["Left Shoulder"].C0
}

tiltAt.OnServerEvent:Connect(function(player, newCalculatedCFrames : table)
	local torso = player.Character.Torso

	torso.BodyAttachJoint.C0 = newCalculatedCFrames.bodyAttachJoint
	torso.Neck.C0 = newCalculatedCFrames.neck
	torso["Right Shoulder"].C0 = newCalculatedCFrames.rightShoulder
	torso["Left Shoulder"].C0 = newCalculatedCFrames.leftShoulder
end)
