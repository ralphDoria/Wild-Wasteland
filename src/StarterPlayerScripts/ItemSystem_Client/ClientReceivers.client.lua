--!nocheck
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage
local gunUtility = ItemSystem_ScriptStorage.Classes.Components.Gun.Utility
local drawRayResults = require(gunUtility.drawRayResults)
local castRays = require(gunUtility.castRays)
local playRandomSoundFromSource = require(gunUtility.playRandomSoundFromSource)

local ToolInfo = ItemSystem_ScriptStorage.Data.ToolInfo

local playSound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

local gunRemotesFolder = ReplicatedStorage.ItemSystem_Storage.Gun.Remotes
local gunRemotes = {
    replicateShot = gunRemotesFolder.ReplicateShot:: UnreliableRemoteEvent,
	replicateItemSound = gunRemotesFolder.ReplicateItemSound:: UnreliableRemoteEvent,
}

local function onReplicateShotEvent(gun: Tool, position: Vector3, rayResults: { castRays.RayResult })
	-- Make sure that the blaster is currently streamed in
	if gun and gun:IsDescendantOf(game) then
		local handle = gun.Handle
		local sounds = gun.Sounds
		local emitter = handle.AudioEmitter
		local muzzle = gun:FindFirstChild("Muzzle", true)

		-- If the blaster has a MuzzleAttachment, we'll use that as the laser starting point, otherwise
		-- default to the blaster's pivot position.
		if muzzle then
			position = muzzle.WorldPosition

			-- Play VFX
			muzzle.FlashEmitter:Emit(1)
		else
			position = gun:GetPivot().Position
		end

		-- Play SFX
		playRandomSoundFromSource(sounds.Shoot, emitter)
	end

	drawRayResults(position, rayResults)
end

local function onReplicateItemSound(gun: Tool, soundName: string)
	local x = ToolInfo[gun]	
	local sound = x.soundObjects[soundName]
	local delayCorrection = sound:GetAttribute("DelayCorreciton")
	if sound then
		playSound(sound, gun:FindFirstChild("BodyAttach"), if delayCorrection then delayCorrection else nil)
	end
end

gunRemotes.replicateShot.OnClientEvent:Connect(onReplicateShotEvent)
gunRemotes.replicateItemSound.OnClientEvent:Connect(onReplicateItemSound)