-- local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)


local hitmarkerSound : Sound = References_ItemSystem.ItemSystem_Storage.Melee.Instances.hitmarker
local meleeRemotes = {
    Hit = References_ItemSystem.ItemSystem_Storage.Melee.Remotes.Hit:: RemoteEvent,
    ToggleSwingTrail = References_ItemSystem.ItemSystem_Storage.Melee.Remotes.ToggleSwingTrail:: RemoteEvent
}
local particles : {[string] : ParticleEmitter} = {
    blood = References_ItemSystem.ItemSystem_Storage.Melee.Instances.Blood
}

-- Gun Item specific modules
local currentCamera = workspace.CurrentCamera
local pistolShell = ReplicatedStorage.Tools.Gun:FindFirstChild("PistolCasingUsed", true)
local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    KEYBOARD_RELOAD_KEY_CODE = Enum.KeyCode.R,
    ACTION_DROP_TOOL = "Dropped",
    ACTION_RELOAD = "Reload",
    ACTION_AIM_DOWN_SIGHT = "AimDownSight"
}
local createBulletEffects = require(ReplicatedStorage.RojoManaged_RS.Utility.createBulletEffects)
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
local indicateDamageToDealer = require(ReplicatedStorage.RojoManaged_RS.Utility.indicateDamageToDealer)

local gunFolder = References_ItemSystem.ItemSystem_Storage.Gun:: Folder
local gunRemotesFolder = gunFolder.Remotes:: Folder
local gunInstancesFolder = gunFolder.Instances:: Folder
local gunRemotes = {
    reload = gunFolder:WaitForChild("Reload"):: RemoteEvent,
    shoot = gunFolder:WaitForChild("Shoot"):: RemoteEvent,
    updateAmmoAttribute = gunFolder:WaitForChild("UpdateAmmoAttributes"):: RemoteEvent
}

local function isFirstPerson()
    return References_ItemSystem.player.Character.Torso.LocalTransparencyModifier >= 1
end


-- Parent Class
local Item = require("../Superclasses/Item")

export type GunState = Item.State | "Reloading" | "Shooting"
export type aimState = "Hipfire" | "ADS"
export type movementState = "Jump" | "Sprint" | "Walk" -- gun animation will change depending on movement state

export type GunObject = Item.ItemObject & {
    cooldown = 0.1, --in rounds/minute (RPM),
    adsSpeed = 0.1,
    damage = 20,
    currentAmmo = if gun:GetAttribute("ammo_current") == 999 then 0 else gun:GetAttribute("ammo_current"),
    MAX_MAG_AMMO = 15,
    ammoType = gun:GetAttribute("AmmoType"),
    blacklistedParts = {},
}

local Gun = {}

function Gun.new(tool: Tool)

    -- TODO: set values, such as damage & ammo, on the server & only have client read from it. USE SERVERSIDE CHECKS

    local self = Item.new(tool)
    self.cooldown = 0.1
    self.adsSpeed = 0.1
    self.damage = 20
    self.currentAmmo
    self.magAmmo = tool:GetAttribute("magAmmo") -- placeholder attribute
    self.MAX_MAG_AMMO = 15
    self.reserveAmmo
    self.ammoType
    self.filteredDescendants
end

function Gun.Destroy(self: GunObject)
end

return Gun