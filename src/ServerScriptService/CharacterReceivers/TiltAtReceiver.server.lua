local ReplicatedStorage = game:GetService("ReplicatedStorage")
local tiltAt = ReplicatedStorage:WaitForChild("CharacterRemotes"):WaitForChild("tiltAt")
local TweenService = game:GetService("TweenService")

local originC0 = {
    neck = ReplicatedStorage.originC0Holder.Torso.Neck.C0,
    rightShoulder = ReplicatedStorage.originC0Holder.Torso["Right Shoulder"].C0,
    leftShoulder = ReplicatedStorage.originC0Holder.Torso["Left Shoulder"].C0
}

local remoteEventFireRate = 0.1
local ti = TweenInfo.new(remoteEventFireRate, Enum.EasingStyle.Linear, Enum.EasingDirection.In)

tiltAt.OnServerEvent:Connect(function(player, newCalculatedCFrames : table, toolEquipped :  boolean)
	-- print("receiving")
	local torso = player.Character.Torso

	--[[
	torso.BodyAttachJoint.C0 = newCalculatedCFrames.bodyAttachJoint
	torso.Neck.C0 = newCalculatedCFrames.neck
	]]
	TweenService:Create(torso.BodyAttachJoint, ti, {C0 = newCalculatedCFrames.bodyAttachJoint}):Play()
	TweenService:Create(torso.Neck, ti, {C0 = newCalculatedCFrames.neck}):Play()
	if toolEquipped then
		--[[
		torso["Right Shoulder"].C0 = newCalculatedCFrames.rightShoulder
		torso["Left Shoulder"].C0 = newCalculatedCFrames.leftShoulder
		]]
		TweenService:Create(torso["Right Shoulder"], ti, {C0 = newCalculatedCFrames.rightShoulder}):Play()
		TweenService:Create(torso["Left Shoulder"], ti, {C0 = newCalculatedCFrames.leftShoulder}):Play()
	else
		--[[
		torso["Right Shoulder"].C0 = originC0.rightShoulder
		torso["Left Shoulder"].C0 = originC0.leftShoulder
		]]
		TweenService:Create(torso["Right Shoulder"], ti, {C0 = originC0.rightShoulder}):Play()
		TweenService:Create(torso["Left Shoulder"], ti, {C0 = originC0.leftShoulder}):Play()
	end
end)
