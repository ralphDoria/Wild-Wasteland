--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage
local gunUtility = ItemSystem_ScriptStorage.Classes.Components.Gun.Utility
local drawRayResults = require(gunUtility.drawRayResults)
local castRays = require(gunUtility.castRays)
local playRandomSoundFromSource = require(gunUtility.playRandomSoundFromSource)

local ToolInfo = require(ItemSystem_ScriptStorage.Data.ToolInfo)

local playSound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

local gunRemotesFolder = ReplicatedStorage.ItemSystem_Storage.Gun.Remotes
local gunRemotes = {
    replicateShot = gunRemotesFolder.ReplicateShot:: UnreliableRemoteEvent,
	replicateItemSound = gunRemotesFolder.ReplicateItemSound:: UnreliableRemoteEvent,
}

local function onReplicateShotEvent(gun: Tool, position: Vector3, rayResults: { castRays.RayResult })
	-- Make sure that the blaster is currently streamed in
	if gun and gun:IsDescendantOf(game) then
		local bodyAttach = gun.BodyAttach
		local sounds = ToolInfo.get(gun.Name).soundObjects
		local muzzle = gun:FindFirstChild("Muzzle", true)

		-- If the blaster has a MuzzleAttachment, we'll use that as the laser starting point, otherwise
		-- default to the blaster's pivot position.
		if muzzle then
			position = muzzle.Position
		else
			position = gun:GetPivot().Position
		end

		-- Play SFX
		local sound = sounds.shoot
		if type(sounds.shoot) == "table" then
			playRandomSoundFromSource(sounds.Shoot, bodyAttach)
		else
			local delayCorrection = sound:GetAttribute("DelayCorrection")
			playSound(sound, gun:FindFirstChild("BodyAttach"), if delayCorrection then delayCorrection else nil)
		end
	end

	drawRayResults(position, rayResults, gun)
end

local function onReplicateItemSound(gun: Tool, soundName: string)
	local x = ToolInfo.get(gun.Name)	
	local sound = x.soundObjects[soundName]
	if sound then
		local delayCorrection = sound:GetAttribute("DelayCorreciton")
		playSound(sound, gun:FindFirstChild("BodyAttach"), if delayCorrection then delayCorrection else nil)
	end
end

gunRemotes.replicateShot.OnClientEvent:Connect(onReplicateShotEvent)
gunRemotes.replicateItemSound.OnClientEvent:Connect(onReplicateItemSound)