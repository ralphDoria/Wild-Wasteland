local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tiltAt = ReplicatedStorage:WaitForChild("tiltAt")
local TweenService = game:GetService("TweenService")

local originC0 = {
    neck = ReplicatedStorage.originC0Holder.Torso.Neck.C0,
    rightShoulder = ReplicatedStorage.originC0Holder.Torso["Right Shoulder"].C0,
    leftShoulder = ReplicatedStorage.originC0Holder.Torso["Left Shoulder"].C0
}

local remoteEventFireRate = 0
local ti = TweenInfo.new(remoteEventFireRate, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

tiltAt.OnServerEvent:Connect(function(player, newCalculatedCFrames : table, toolEquipped :  boolean)
	local torso = player.Character.Torso

	--[[ This method that is commented out may be more efficient for the server since it would be receiving a remote event every 0.2 seconds
	TweenService:Create(torso.BodyAttachJoint, ti, {C0 = newCalculatedCFrames.bodyAttachJoint}):Play()
	TweenService:Create(torso.Neck, ti, {C0 = newCalculatedCFrames.neck}):Play()
	TweenService:Create(torso["Right Shoulder"], ti, {C0 = newCalculatedCFrames.rightShoulder}):Play()
	TweenService:Create(torso["Left Shoulder"], ti, {C0 = newCalculatedCFrames.leftShoulder}):Play()
	]]

	--This method below is the most responsive, but also puts more load on the server because it receives a remote event fire signal every 
	--render step, though I don't know if that difference in load is negligible. With one player testing, it seems like it is.
	torso.BodyAttachJoint.C0 = newCalculatedCFrames.bodyAttachJoint
	torso.Neck.C0 = newCalculatedCFrames.neck
	if toolEquipped then
		torso["Right Shoulder"].C0 = newCalculatedCFrames.rightShoulder
		torso["Left Shoulder"].C0 = newCalculatedCFrames.leftShoulder
	else
		torso["Right Shoulder"].C0 = originC0.rightShoulder
		torso["Left Shoulder"].C0 = originC0.leftShoulder
	end
end)
