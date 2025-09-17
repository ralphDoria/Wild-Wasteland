local castRays = require(script.Parent.castRays)

local Constants = require(script.Parent.Parent.Constants)
local laserBeamEffect = require(script.Parent.Effects.laserBeamEffect)
local impactEffect = require(script.Parent.Effects.impactEffect)
local muzzleFlashEffect = require(script.Parent.Effects.muzzleFlashEffect)

local function isEnergyWeapon(gun: Tool): laserBeamEffect.beamType
	if gun:GetAttribute(Constants.AMMO_TYPE_ATTRIBUTE) == "Energy Cores" then
		return "Energy"
	else
		return "Ballistic"
	end
end
--[[
	The muzzle part is to create for muzzle flash
]]
local function drawRayResults(position: Vector3, rayResults: { castRays.RayResult }, gun: Tool, muzzle)
	for _, rayResult in rayResults do
		laserBeamEffect(position, rayResult.position, isEnergyWeapon(gun))
		if muzzle then
			muzzleFlashEffect(muzzle)
		end

		if rayResult.instance then
			impactEffect(rayResult.position, rayResult.normal, rayResult.taggedHumanoid ~= nil, rayResult.instance.Material, gun)
		end
	end
end

return drawRayResults
