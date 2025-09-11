-- local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local ItemSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage
local References_ItemSystem = require(ItemSystem_ScriptStorage.References_ItemSystem)

local GunComponents = ItemSystem_ScriptStorage.Classes.Components.Gun
local Constants = require(GunComponents.Constants)
local GunUtility = GunComponents.Utility
local CameraRecoiler = require(GunUtility.CameraRecoiler)
local getRayDirections = require(GunUtility.getRayDirections)
local castRays = require(GunUtility.castRays)
local drawRayResults = require(GunUtility.drawRayResults)
local bindSoundsToAnimationEvents = require(GunUtility.bindSoundsToAnimationEvents)

local gunRemotesFolder = References_ItemSystem.ItemSystem_Storage.Gun.Remotes
local gunRemotes = {
    shoot = gunRemotesFolder.Shoot:: RemoteEvent,
    reload = gunRemotesFolder.Reload:: RemoteEvent,
	replicateItemSound = gunRemotesFolder.ReplicateItemSound:: UnreliableRemoteEvent,
}

-- Gun Item specific modules
local camera = workspace.CurrentCamera
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
local hitmarkerSound : Sound = References_ItemSystem.ItemSystem_Storage.Melee.Instances.hitmarker
local pistolShell = ReplicatedStorage:FindFirstChild("PistolCasingUsed", true)
-- local indicateDamageToDealer = require(ReplicatedStorage.RojoManaged_RS.Utility.indicateDamageToDealer)

local random = Random.new()

-- Parent Class
local Item = require("../Superclasses/Item")

export type GunObject = Item.ItemObject & {
	muzzle: Part,
	aimPart: Part,
    ammo: number,

	-- boolean states
	isAiming: boolean,
	isSprinting: boolean,
	isReloading: boolean,
	isShooting: boolean,
	isActivated: boolean
}

local Gun = {}

function Gun.new(tool: Tool): GunObject

    local self = Item.new(tool)

	local vmTool = References_ItemSystem.viewmodelManagerObject.ToolToVMToolMapping[tool]
	if vmTool then print("Found ViewmodelTool") end
	local muzzle = vmTool:WaitForChild("Muzzle"):: Part
	local aimPart = vmTool:WaitForChild("AimPart"):: Part

	self.muzzle = muzzle
	self.aimPart = aimPart
    self.ammo = tool:GetAttribute(Constants.AMMO_ATTRIBUTE)
	-- boolean states
	self.isAiming = false
	self.isSprinting = false
	self.isReloading = false
	self.isShooting = false
	self.isActivated = false

    Gun.initialize(self)
    return self
end

function Gun.initialize(self: GunObject)
    Item.initialize(
        self,
        function()  --onEquipping
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			-- Resync ammo and reloading values
			self.ammo = self.tool:GetAttribute(Constants.AMMO_ATTRIBUTE):: number
			self.isReloading = false

			-- Enable GUI
			References_ItemSystem.ItemHUD.setAmmo(self.ammo)
			References_ItemSystem.ItemHUD.setReloading(self.isReloading)

			Gun.toggleActivateBind(self, true)
			Gun.toggleReloadBind(self, true)
        end, 
        function() --onEquipped
        end,
        function() --onUnequipping
			-- Force deactivate the blaster when unequipping it
			Gun.deactivate(self) -- for safety, may be dead code
			Gun.toggleActivateBind(self, false)
			Gun.toggleReloadBind(self, false)
			player.CameraMode = Enum.CameraMode.Classic
        end,
        function() --onUnequipped()
        end, 
        function() --onDropping()
			Gun.deactivate(self) -- for safety, may be dead code
			Gun.toggleActivateBind(self, false)
			Gun.toggleReloadBind(self, false)
        end,
        function() --onDropped()
        end
    )

end

function Gun.recoil(self: GunObject)
	local recoilMin = self.tool:GetAttribute(Constants.RECOIL_MIN_ATTRIBUTE)
	local recoilMax = self.tool:GetAttribute(Constants.RECOIL_MAX_ATTRIBUTE)

	local xDif = recoilMax.X - recoilMin.X
	local yDif = recoilMax.Y - recoilMin.Y
	local x = recoilMin.X + random:NextNumber() * xDif
	local y = recoilMin.Y + random:NextNumber() * yDif

	local recoil = Vector2.new(math.rad(-x), math.rad(y))

	CameraRecoiler.recoil(recoil)
end

function Gun.shoot(self: GunObject)
	local spread = self.tool:GetAttribute(Constants.SPREAD_ATTRIBUTE)
	local raysPerShot = self.tool:GetAttribute(Constants.RAYS_PER_SHOT_ATTRIBUTE)
	local range = self.tool:GetAttribute(Constants.RANGE_ATTRIBUTE)
	local rayRadius = self.tool:GetAttribute(Constants.RAY_RADIUS_ATTRIBUTE)


	
	if not self.isAiming then
		References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].hipfire:Play()
        References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].hipfire:Play()
	else
		References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].ADS_fire:Play()
        References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].hipfire:Play()
	end
	Gun.recoil(self)

	self.ammo -= 1

	References_ItemSystem.ItemHUD.setAmmo(self.ammo)

	local now = game.Workspace:GetServerTimeNow()
	local origin = camera.CFrame

	local rayDirections = getRayDirections(origin, raysPerShot, math.rad(spread), now)
	for index, direction in rayDirections do
		rayDirections[index] = direction * range
	end

	local rayResults = castRays(player, origin.Position, rayDirections, rayRadius)

	-- Rather than passing the entire table of rayResults to the server, we'll pass the shot origin and a list of tagged humanoids.
	-- The server will then recalculate the ray directions from the origin and validate the tagged humanoids.
	-- Strings are used for the indices since non-contiguous arrays do not get passed over the network correctly.
	-- (This may be non-contiguous in the case of firing a shotgun, where not all of the rays hit a target)
	local tagged = {}
	local didTag = false
	for index, rayResult in rayResults do
		if rayResult.taggedHumanoid then
			tagged[tostring(index)] = rayResult.taggedHumanoid
			didTag = true
		end
	end

	if didTag then
        References_ItemSystem.CrosshairGuiManager.showHitmarker(References_ItemSystem.crosshairGuiObject, function()  
			playSound(hitmarkerSound, self.bodyAttach, 0)
        end)
	end

	gunRemotes.shoot:FireServer(now, self.tool, origin, tagged)
	local shootSound = self.soundObjects.shoot
	playSound(shootSound, self.tool:FindFirstChild("BodyAttach"))
	gunRemotes.replicateItemSound:FireServer(self.tool, shootSound.Name)

	local muzzlePosition = self.muzzle.Position -- remember that this is the muzzle position of the viewmodel tool
	drawRayResults(muzzlePosition, rayResults, self.tool)
end

function Gun.startShooting(self: GunObject)
	-- If the player tries to shoot without any ammo, reload instead
	if self.ammo <= 0 then
		local dryFireSound = self.soundObjects.dryFire
		playSound(dryFireSound, self.tool:FindFirstChild("BodyAttach"))
		gunRemotes.replicateItemSound:FireServer(self.tool, dryFireSound.Name)
		return
	end

	if self.isShooting or self.isReloading then
		return
	end

	local fireMode = self.tool:GetAttribute(Constants.FIRE_MODE_ATTRIBUTE)
	local rateOfFire = self.tool:GetAttribute(Constants.RATE_OF_FIRE_ATTRIBUTE)

	if fireMode == Constants.FIRE_MODE.SEMI then
		self.isShooting = true
		Gun.shoot(self)
		task.delay(60 / rateOfFire, function()
			self.isShooting = false
		end)
	elseif fireMode == Constants.FIRE_MODE.AUTO then
		task.spawn(function()
			self.isShooting = true
			while self.isActivated and self.ammo > 0 and not self.isReloading do
				Gun.shoot(self)
				task.wait(60 / rateOfFire)
			end
			self.isShooting = false

			if self.ammo == 0 then
				local dryFireSound = self.soundObjects.dryFire
				playSound(dryFireSound, self.tool:FindFirstChild("BodyAttach"))
				gunRemotes.replicateItemSound:FireServer(self.tool, dryFireSound.Name)
			end
		end)
	end
end

function Gun.reload(self: GunObject)
	local magSize = self.tool:GetAttribute(Constants.MAGAZINE_SIZE_ATTRIBUTE)
	if not (self.ammo < magSize and not self.isReloading) then
		return
	end

	local magazineSize = self.tool:GetAttribute(Constants.MAGAZINE_SIZE_ATTRIBUTE)

	-- self.viewModelController:playReloadAnimation(reloadTime)
	-- self.characterAnimationController:playReloadAnimation(reloadTime)
	local reloadTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].reload
	local vmReloadTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].reload
	reloadTrack:Play()
	vmReloadTrack:Play()

	self.isReloading = true
	References_ItemSystem.ItemHUD.setReloading(self.isReloading)
	local reloadSounds = self.soundObjects.reload
	local soundBinding = self.trove:Connect(vmReloadTrack:GetMarkerReachedSignal("Sound"), function(param)  
		local sound = reloadSounds[param]
		if not sound then return end
		playSound(sound, self.tool:FindFirstChild("BodyAttach"))
		gunRemotes.replicateItemSound:FireServer(self.tool, sound.Name)
		if param == "magIn" then
			gunRemotes.reload:FireServer(self.tool)
			self.ammo = magazineSize
			self.isReloading = false
			References_ItemSystem.ItemHUD.setAmmo(self.ammo)
			References_ItemSystem.ItemHUD.setReloading(self.isReloading)
		end
	end)

	vmReloadTrack.Stopped:Once(function()  
		if soundBinding then
			soundBinding:Disconnect()	
		end
	end)
end

function Gun.activate(self: GunObject)
	if self.isActivated then
		return
	end
	self.isActivated = true

	Gun.startShooting(self)
end

function Gun.deactivate(self: GunObject)
	if not self.isActivated then
		return
	end
	self.isActivated = false
end

function Gun.toggleActivateBind(self: GunObject, toggle : boolean)
	self.actionNames.activate = "Activate"
	local actionName = self.actionNames.activate
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
            actionName, 
            function(): (() -> (), () -> (), () -> ())  

                local function onActivated()
					Gun.activate(self)
                end

                local function onDeactivated()
					Gun.deactivate(self)
                end

                local function onUnbind()
					Gun.deactivate(self)
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.UserInputType.MouseButton1,
            Enum.KeyCode.ButtonR2, 
            3, 
            nil, 
            nil,
            "rbxassetid://115424809980399")
    else
        References_ItemSystem.ActionManager.unbindAction(actionName)
    end
end

function Gun.toggleReloadBind(self: GunObject, toggle : boolean)
	self.actionNames.reload = "Reload"
	local actionName = self.actionNames.reload
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
            actionName, 
            function(): (() -> (), () -> (), () -> ())  

                local function onActivated()
					Gun.reload(self)
                end

                local function onDeactivated()
                end

                local function onUnbind()
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Constants.KEYBOARD_RELOAD_KEY_CODE,
            Constants.GAMEPAD_RELOAD_KEY_CODE, 
            5, 
            nil, 
            nil,
            "rbxassetid://129530319713241")
    else
        References_ItemSystem.ActionManager.unbindAction(actionName)
    end
end

-- function Gun.toggleADS(toggle: boolean)
-- 	if toggle then

-- 	end
-- end

-- function Gun.toggleAimingBind(self: GunObject, toggle : boolean)
-- 	self.actionNames.aiming = "Aiming"
-- 	local actionName = self.actionNames.aiming
--     if toggle then
--         References_ItemSystem.ActionManager.bindAction(
--             actionName, 
--             function(): (() -> (), () -> (), () -> ())  

--                 local function onActivated()
-- 					Gun.activate(self)
--                 end

--                 local function onDeactivated()
-- 					Gun.deactivate(self)
--                 end

--                 local function onUnbind()
-- 					Gun.deactivate(self)
--                 end

--                 return onActivated, onDeactivated, onUnbind
--             end, 
--             Enum.UserInputType.MouseButton2,
--             Enum.KeyCode.ButtonL2, 
--             6, 
--             nil, 
--             nil,
--             "rbxassetid://137793533654676")
--     else
--         References_ItemSystem.ActionManager.unbindAction(actionName)
--     end
-- end


function Gun.Destroy(self: GunObject)
	Item.Destroy(self, function()  
		
	end)
end

return Gun