local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Constants = require(script.Parent.Parent.Parent.Constants)

local BeamTemplatesFolder = ReplicatedStorage.ItemSystem_Storage.Gun.Instances.BeamTemplates:: Folder
local beamTemplates = {
    Ballistic = BeamTemplatesFolder.BallisticTracerBeam,
    Energy = BeamTemplatesFolder.EnergyBeam 
}

export type beamType = "Ballistic" | "Energy"

local function laserBeamEffect(startPosition: Vector3, endPosition: Vector3, beamType: beamType)
    local beamTemplate = beamTemplates[beamType]
	assert(beamTemplate, `Could not find beamTemplate with beamType of {beamType}`)

	local distance = (startPosition - endPosition).Magnitude
	local tweenTime = distance / Constants.LASER_BEAM_VISUAL_SPEED
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local laser = beamTemplate:Clone()
	laser.CFrame = CFrame.lookAt(startPosition, endPosition)
	laser.StartAttachment.Position = Vector3.zero
	laser.EndAttachment.Position = Vector3.new(0, 0, -distance)
	laser.Parent = Workspace

	local tween = TweenService:Create(laser.StartAttachment, tweenInfo, { Position = laser.EndAttachment.Position })
	tween:Play()
	tween.Completed:Once(function()
		laser:Destroy()
	end)
end

return laserBeamEffect
