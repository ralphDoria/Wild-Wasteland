--!strict
-- local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
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
local StackableSlotFinder = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.StackableSlotFinder)

local gunRemotesFolder = References_ItemSystem.ItemSystem_Storage.Gun.Remotes
local gunRemotes = {
    shoot = gunRemotesFolder.Shoot:: RemoteEvent,
    reload = gunRemotesFolder.Reload:: RemoteEvent,
}
local replicateItemSound: UnreliableRemoteEvent = References_ItemSystem.ItemSystem_Storage.Shared.Remotes.ReplicateItemSound

-- Gun Item specific modules
local camera = workspace.CurrentCamera
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
local hitmarkerSound : Sound = References_ItemSystem.ItemSystem_Storage.Melee.Instances.hitmarker
local pistolShell = ReplicatedStorage:FindFirstChild("PistolCasingUsed", true)
-- local indicateDamageToDealer = require(ReplicatedStorage.RojoManaged_RS.Utility.indicateDamageToDealer)

local random = Random.new()

-- Parent Class
local Item = require("../Superclasses/Item")

export type GunState = Item.State | "Shooting" | "Reloading" | "Inspecting"

export type GunObject = Item.ItemObject & {
	muzzle: Part,
	aimPart: Part,
	shellSpawnPart: Part,
    ammo: number,
	aimingSpeed: number,

	-- boolean states
	isAiming: boolean,
	isSprinting: boolean,
	isActivated: boolean
}

local Gun = {}

function Gun.new(tool: Tool): GunObject

    local self = Item.new(tool):: GunObject

	local vmTool = References_ItemSystem.viewmodelManagerObject.ToolToVMToolMapping[tool]
	if vmTool then print("Found ViewmodelTool") end
	local muzzle = vmTool:WaitForChild("Muzzle"):: Part
	local aimPart = vmTool:WaitForChild("AimPart"):: Part
	local shellSpawnPart = vmTool:WaitForChild("ShellSpawnPart"):: Part
	local ammo = tool:GetAttribute(Constants.AMMO_ATTRIBUTE)
	assert(typeof(ammo) == "number", `{ammo} is not a number`)
	local aimingSpeed = tool:GetAttribute(Constants.AIMING_SPEED_ATTRIBUTE)
	assert(typeof(aimingSpeed) == "number", `{aimingSpeed} is not a number`)

	self.muzzle = muzzle
	self.aimPart = aimPart
	self.shellSpawnPart = shellSpawnPart
    self.ammo = ammo
	self.aimingSpeed = aimingSpeed
	-- boolean states
	self.isAiming = false
	References_ItemSystem.viewmodelManagerObject.viewmodel:SetAttribute("isAiming", self.isAiming) -- for viewbobing calculations
	self.isSprinting = false
	self.isActivated = false

    Gun.initialize(self)
    return self
end

function Gun.initialize(self: GunObject)
	   
	local function onUnequip()
		-- Force deactivate the blaster when unequipping it
		Gun.deactivate(self) -- for safety, may be dead code
		Gun.toggleActivateBind(self, false)
		Gun.toggleReloadBind(self, false)
		Gun.toggleAimingBind(self, false)
		Gun.toggleInspectBind(self, false)
		Gun.toggleAiming(self, false)
		player.CameraMode = Enum.CameraMode.Classic
	end

    Item.initialize(
        self,
        function()  --onEquipping
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			-- Resync ammo and reloading values
			self.ammo = self.tool:GetAttribute(Constants.AMMO_ATTRIBUTE):: number

			-- Enable GUI
			References_ItemSystem.ItemHUD.setAmmo(self.ammo)
			References_ItemSystem.ItemHUD.setReloading(self.State:: GunState == "Reloading")
        end, 
        function() --onEquipped
			Gun.toggleActivateBind(self, true)
			Gun.toggleReloadBind(self, true)
			Gun.toggleAimingBind(self, true)
			Gun.toggleInspectBind(self, true)
        end,
        function() --onUnequipping
			warn("unequipping gun")
			onUnequip()
        end,
        function() --onUnequipped()
        end, 
        function() --onDropping()
			onUnequip()
        end,
        function() --onDropped()
        end
    )

	--CFrame recoil for when aiming because viewmodel aiming animation only animates blowback, movement recoil
	self.trove:Connect(References_ItemSystem.RunService.RenderStepped, function(deltaTime: number)
		local vmAimingShootTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].ADS_shoot
		if not vmAimingShootTrack or not vmAimingShootTrack.IsPlaying then return end

		local vmHead: BasePart = References_ItemSystem.viewmodelManagerObject.viewmodel:FindFirstChild("Head"):: BasePart
		if not vmHead then return end

		local aiming_recoil_offset = CFrame.new(0, 0, 0.3) * CFrame.Angles(math.rad(5), 0, 0)
		local alpha = vmAimingShootTrack.TimePosition/vmAimingShootTrack.Length
		--print(alpha) | isn't reaching 1, but it doesn't matter because it's just the recoil animation and the last frame isn't really needed to be shown
		local transition_ads_recoil_offset = CFrame.new():Lerp(aiming_recoil_offset, alpha)
		vmHead.CFrame *= transition_ads_recoil_offset
	end)

end

function Gun.recoil(self: GunObject)
	local recoilMin: Vector2 = self.tool:GetAttribute(Constants.RECOIL_MIN_ATTRIBUTE):: Vector2
	local recoilMax: Vector2 = self.tool:GetAttribute(Constants.RECOIL_MAX_ATTRIBUTE):: Vector2

	local xDif = recoilMax.X - recoilMin.X
	local yDif = recoilMax.Y - recoilMin.Y
	local x = recoilMin.X + random:NextNumber() * xDif
	local y = recoilMin.Y + random:NextNumber() * yDif

	local recoil = Vector2.new(math.rad(-x), math.rad(y))

	CameraRecoiler.recoil(recoil)
end

function Gun._shellEjection(self: GunObject)
	--shell ejection (all client side)
	local shell = pistolShell:Clone():: BasePart
	shell.Anchored = false --temporary to check if the shell is being positioned properly
	shell.CFrame = self.shellSpawnPart.CFrame * CFrame.Angles(math.rad(90), 0, 0)
	shell.Parent = workspace
	--later, incorporate character velocity to adjust force
	local finalPosition = (shell.CFrame * CFrame.new(Vector3.new(-30, 0, 20))).Position  --seems to behave like this: Vector3.new(x, z, y)
	local direction : Vector3 = shell.CFrame.Position - finalPosition
	shell:ApplyImpulseAtPosition(direction * shell.AssemblyMass, shell.Position - Vector3.new(0, 0, -10))
	Debris:AddItem(shell, 2)
end

function Gun.shoot(self: GunObject)
	local spread = self.tool:GetAttribute(Constants.SPREAD_ATTRIBUTE):: number
	local raysPerShot = self.tool:GetAttribute(Constants.RAYS_PER_SHOT_ATTRIBUTE):: number
	local range = self.tool:GetAttribute(Constants.RANGE_ATTRIBUTE):: number
	local rayRadius = self.tool:GetAttribute(Constants.RAY_RADIUS_ATTRIBUTE):: number

	if not self.isAiming then
		References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].hipfire:Play()
        References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].hipfire:Play()
	else
		References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].ADS_viewmodelShoot:Play()
        References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].ADS_shoot:Play()
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
	replicateItemSound:FireServer(self.tool, shootSound.Name)

	local muzzlePosition = self.muzzle.Position -- remember that this is the muzzle position of the viewmodel tool
	Gun._shellEjection(self)
	drawRayResults(muzzlePosition, rayResults, self.tool, self.muzzle)
end

function Gun.startShooting(self: GunObject)
	-- If the player tries to shoot without any ammo, reload instead
	if self.ammo <= 0 then
		local dryFireSound = self.soundObjects.dryFire
		playSound(dryFireSound, self.tool:FindFirstChild("BodyAttach"))
		replicateItemSound:FireServer(self.tool, dryFireSound.Name)
		return
	end

	local gunState: GunState = self.State
	if gunState == "Shooting" or gunState == "Reloading" then
		return
	end

	local fireMode = self.tool:GetAttribute(Constants.FIRE_MODE_ATTRIBUTE)
	local rateOfFire = self.tool:GetAttribute(Constants.RATE_OF_FIRE_ATTRIBUTE):: number

	if fireMode == Constants.FIRE_MODE.SEMI then
		Gun.ChangeState(self, "Shooting")
		Gun.shoot(self)
		task.delay(60 / rateOfFire, function()
			Gun.ChangeState(self, "Idle")
		end)
	elseif fireMode == Constants.FIRE_MODE.AUTO then
		task.spawn(function()
			Gun.ChangeState(self, "Shooting")
			while self.isActivated and self.ammo > 0 do
				Gun.shoot(self)
				task.wait(60 / rateOfFire)
			end
			Gun.ChangeState(self, "Idle")

			if self.ammo == 0 then
				local dryFireSound = self.soundObjects.dryFire
				playSound(dryFireSound, self.tool:FindFirstChild("BodyAttach"))
				replicateItemSound:FireServer(self.tool, dryFireSound.Name)
			end
		end)
	end
end

function Gun.reload(self: GunObject)
	local magSize = self.tool:GetAttribute(Constants.MAGAZINE_SIZE_ATTRIBUTE):: number
	local ammoReserve = StackableSlotFinder.getSum(self.tool:GetAttribute(Constants.AMMO_TYPE_ATTRIBUTE):: string):: number
	print(ammoReserve)

	if self.ammo >= magSize then 
		warn("Gun is already fully loaded.")
		return 
	end
	if self.State:: GunState == "Reloading" then 
		warn("Already reloading.")
		return 
	end
	if self.isAiming then 
		warn("Can't reloading while aiming.") 
		return 
	end
	if ammoReserve <= 0 then 
		warn("Not enough ammo") 
		return 
	end


	local difference = magSize - self.ammo
	local ammoToLoad = math.min(magSize, ammoReserve, difference)

	local reloadTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].reload
	local vmReloadTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].reload
	reloadTrack:Play()
	vmReloadTrack:Play()

	Gun.ChangeState(self, "Reloading")
	References_ItemSystem.ItemHUD.setReloading(self.State:: GunState == "Reloading")

	vmReloadTrack.Stopped:Once(function()  
		gunRemotes.reload:FireServer(self.tool)
		Gun.ChangeState(self, "Idle")
		self.ammo += ammoToLoad
		References_ItemSystem.ItemHUD.setAmmo(self.ammo)
		References_ItemSystem.ItemHUD.setReloading(false)
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

function Gun.ChangeState(self: GunObject, state: GunState)
    if self.tool then
        self.tool:SetAttribute("State", state)
    else
        warn("Tool seems to already have been destroyed, cannot change its state")
    end
    self.State = state:: Item.State -- just casting to to Item.State to remove type check errors
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

local RunService = References_ItemSystem.RunService
local transitioningToAiming: RBXScriptConnection
local detransitioningFromAiming: RBXScriptConnection
local targetAimingCFrame: CFrame = CFrame.new()
local aimTransitionTimeAccumulated = 0
local function disconnectAimingEventListeners()
	if transitioningToAiming then
		transitioningToAiming:Disconnect()
	end
	if detransitioningFromAiming then
		detransitioningFromAiming:Disconnect()
	end
end

function Gun.toggleAiming(self: GunObject, toggle: boolean)
	if self.State:: GunState == "Reloading" then return end

	if toggle then
		self.isAiming = true
		local inspectTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].inspect
		if inspectTrack then
			References_ItemSystem.ActionManager.forceToggle("Inspect", false)
		end
		References_ItemSystem.viewmodelManagerObject.viewmodel:SetAttribute("isAiming", self.isAiming)
		References_ItemSystem.CrosshairGuiManager.toggleReticle(false)
		References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].ADS_idle:Play(self.aimingSpeed)
		References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].ADS_idle:Play(self.aimingSpeed)
		self.soundObjects.ADS_in:Play()


		local aimingOffsetCorrection = CFrame.new(self.tool:GetAttribute(Constants.AIMING_OFFSET_CORRECTION_ATTRIBUTE):: Vector3)

		disconnectAimingEventListeners()
		transitioningToAiming = RunService.RenderStepped:Connect(function(dt: number)  
			local aimPartOffsetFromCamera = self.aimPart.CFrame:ToObjectSpace(workspace.CurrentCamera.CFrame)
			targetAimingCFrame = aimingOffsetCorrection * aimPartOffsetFromCamera 
			aimTransitionTimeAccumulated = math.clamp(aimTransitionTimeAccumulated + dt, 0, self.aimingSpeed)
			local lerpAlpha = math.clamp(aimTransitionTimeAccumulated/self.aimingSpeed, 0, 1)
			local vmHead = References_ItemSystem.viewmodelManagerObject.viewmodel:FindFirstChild("Head"):: BasePart?
			if vmHead then
				vmHead.CFrame *= CFrame.new():Lerp(targetAimingCFrame, lerpAlpha)
				-- if lerpAlpha == 1 then
				-- 	if transitioningToAiming then
				-- 		transitioningToAiming:Disconnect()
				-- 	end
				-- end
			end
		end)
	else
		References_ItemSystem.CrosshairGuiManager.toggleReticle(true)
		References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].ADS_idle:Stop(self.aimingSpeed)
		References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].ADS_idle:Stop(self.aimingSpeed)
		self.soundObjects.ADS_out:Play()

		disconnectAimingEventListeners()
		detransitioningFromAiming = RunService.RenderStepped:Connect(function(dt: number)  
			if not self.aimingSpeed then 
				detransitioningFromAiming:Disconnect()
				return 
			end -- Need to check after connecting because it seems to run deferred. This needed for calculations below and would cause an error if it's nil
			aimTransitionTimeAccumulated = math.clamp(aimTransitionTimeAccumulated - dt, 0, self.aimingSpeed)
			local lerpAlpha = math.clamp(aimTransitionTimeAccumulated/self.aimingSpeed, 0, 1)
			local vmHead = References_ItemSystem.viewmodelManagerObject.viewmodel:FindFirstChild("Head"):: BasePart?
			if vmHead then
				vmHead.CFrame *= CFrame.new():Lerp(targetAimingCFrame, lerpAlpha)
				if lerpAlpha == 0 then
					if detransitioningFromAiming then
						detransitioningFromAiming:Disconnect()
						self.isAiming = false
						References_ItemSystem.viewmodelManagerObject.viewmodel:SetAttribute("isAiming", self.isAiming)
					end
				end
			end
		end)
	end
end

function Gun.toggleAimingBind(self: GunObject, toggle : boolean)
	self.actionNames.aiming = "Aiming"
	local actionName = self.actionNames.aiming
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
            actionName, 
            function(): (() -> (), () -> (), () -> ())  

                local function onActivated()
					Gun.toggleAiming(self, true)
                end

                local function onDeactivated()
					Gun.toggleAiming(self, false)
                end

                local function onUnbind()
					disconnectAimingEventListeners()
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.UserInputType.MouseButton2,
            Enum.KeyCode.ButtonL2, 
            6, 
            false, 
            nil,
            "rbxassetid://137793533654676")
    else
        References_ItemSystem.ActionManager.unbindAction(actionName)
    end
end

function Gun.toggleInspect(self: GunObject, toggle: boolean)
	local inspectTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].inspect
	local vmInspectTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].inspect
	if not inspectTrack then return end
	local gunState: GunState = self.State
	if toggle then

		inspectTrack:Play()
		vmInspectTrack:Play()
		Gun.ChangeState(self, "Inspecting")
		self.tool:GetAttributeChangedSignal("State"):Once(function()  
			if inspectTrack.IsPlaying then
				inspectTrack:Stop()
				vmInspectTrack:Stop()
			end
		end)
		inspectTrack.Stopped:Once(function(...: any)  
			if self.State:: GunState == "Inspecting" then
				Gun.ChangeState(self, "Idle")
			end
		end)
	else
		if gunState == "Inspecting" then
			inspectTrack:Stop()
			vmInspectTrack:Stop()
			Gun.ChangeState(self, "Idle")
		end
	end
end

function Gun.toggleInspectBind(self: GunObject, toggle : boolean)
	self.actionNames.aiming = "Inspect"
	local actionName = self.actionNames.aiming
	if not References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].inspect then return end
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
            actionName, 
            function(): (() -> (), () -> (), () -> ())  

                local function onActivated()
					Gun.toggleInspect(self, true)
                end

                local function onDeactivated()
					Gun.toggleInspect(self, false)
				end

                local function onUnbind()
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.KeyCode.G,
            Enum.KeyCode.DPadLeft, 
            7, 
            false, 
            nil,
            "rbxassetid://137793533654676",
            function(): boolean
                if not (self.State == "Idle") then
                    return false
                end

                if self.isAiming then
                    return false
                end

                return true
            end
		)
    else
        References_ItemSystem.ActionManager.unbindAction(actionName)
    end
end

function Gun.Destroy(self: GunObject)
	Item.Destroy(self, function()  
		
	end)
end

return Gun