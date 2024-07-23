local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local SoundService = game:GetService("SoundService")

local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    KEYBOARD_RELOAD_KEY_CODE = Enum.KeyCode.R,
    ACTION_DROP_TOOL = "Dropped",
    ACTION_RELOAD = "Reload",
    ACTION_AIM_DOWN_SIGHT = "AimDownSight"
}

local AnimationController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("AnimationController"))
local ViewModelController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("ViewModelController"))

local toolGuiController = require(ReplicatedStorage:FindFirstChild("ToolGuiController", true))
local createBulletEffects = require(ReplicatedStorage.RojoManaged_RS.Utility.createBulletEffects)
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
local indicateDamageToDealer = require(ReplicatedStorage.RojoManaged_RS.Utility.indicateDamageToDealer)

local gunRemotes : Folder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Gun"):WaitForChild("Remotes")
local rev_playSound : RemoteEvent = gunRemotes:WaitForChild("PlaySound")
local rev_droppedTool : RemoteEvent = gunRemotes:WaitForChild("DroppedTool")
local rev_reload : RemoteEvent = gunRemotes:WaitForChild("Reload")
local rev_shoot : RemoteEvent = gunRemotes:WaitForChild("Shoot")
local rev_updateAmmoAttribute : RemoteEvent = gunRemotes:WaitForChild("UpdateAmmoAttributes")


local function isFirstPerson()
    return Players.LocalPlayer.Character.Torso.LocalTransparencyModifier >= 1
end

--managing ammo attributes
local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))
while not player:GetAttribute("StatsLoaded") do
    task.wait()
    --print("loading stats")
end

local GunController = {}
GunController.__index = GunController

function GunController.new(gun : Tool)
    local animObjects = {
        equip = gun:WaitForChild("Anims"):WaitForChild("equip"),
        idle = gun:WaitForChild("Anims"):WaitForChild("idle"),
        hipfire = gun:WaitForChild("Anims"):WaitForChild("hipfire"),
        adsFire = gun:WaitForChild("Anims"):WaitForChild("adsFire"),
        viewModelFire = gun:WaitForChild("Anims"):WaitForChild("viewModelFire"),
        reload = gun:WaitForChild("Anims"):WaitForChild("reload"),
        adsIdle = gun:WaitForChild("Anims"):WaitForChild("adsIdle"),
        sprint = gun:WaitForChild("Anims"):WaitForChild("sprint")
    }
    --local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait() |this may not be needed
    local hrp = character:WaitForChild("HumanoidRootPart")

    local aiming = false

    local self = {
        tool = gun,
        name = "Beretta",
        animObjects = animObjects,
        currentCharacterAnimationController = nil,
        currentPlayer = nil,
        currentCharacter = nil,
        SFX_part = gun:WaitForChild("SFX_part"),
        soundObjects = {
            ["equip"]           = gun:WaitForChild("SFX_part"):WaitForChild("gun equip"),
            --reload
	        ["magIn"]           = gun:WaitForChild("SFX_part"):WaitForChild("[SFX] m9_magInsert"),
            ["magOut"]          = gun:WaitForChild("SFX_part"):WaitForChild("[SFX] m9_magOut"),
            ["slideBack"]       = gun:WaitForChild("SFX_part"):WaitForChild("[SFX] m9_slideBack"),
            ["slideRelease"]    = gun:WaitForChild("SFX_part"):WaitForChild("[SFX] m9_slideRelease"),
            --activate
            ["fire"]            = gun:WaitForChild("SFX_part"):WaitForChild("M9 Fire [Insurgency Sandstorm]"),
            ["dryFire"]         = gun:WaitForChild("SFX_part"):WaitForChild("Ammo Magazine 3 (SFX) (dryfire)"),
            --Aim down sight
            ["adsIn"]           = gun:WaitForChild("SFX_part"):WaitForChild("ads_in"),
            ["adsOut"]          = gun:WaitForChild("SFX_part"):WaitForChild("ads_out"),
            ["fleshImpact"] = gun:WaitForChild("SFX_part"):WaitForChild("bulletImpact"):WaitForChild("flesh"),
            ["hardImpact"] = gun:WaitForChild("SFX_part"):WaitForChild("bulletImpact"):WaitForChild("hardSurface")
        },
        viewModelController = ViewModelController.new(workspace.CurrentCamera:WaitForChild("viewModel"), gun, animObjects, hrp),
        canActivate = false,
        canReload = false,
        canAimDownSight = false,
        cancelReload = false,
        equipped = false,
        reloading = false,
        aiming = aiming,
        cooldown = 0.1, --in rounds/minute (RPM),
        adsSpeed = 0.1,
        damage = 20,
        currentAmmo = if gun:GetAttribute("ammo_current") == 999 then 0 else gun:GetAttribute("ammo_current"),
        MAX_MAG_AMMO = 15,
        ammoType = gun:GetAttribute("AmmoType"),
        blacklistedParts = {},
        connections = {}
    }
    self.viewModelController.adsSpeed = self.adsSpeed
    assert(self.tool.RequiresHandle == false, "Need to turn of RequiresHandle in the given tool")
    setmetatable(self, GunController)
    self:initialize()
    return self
end

function GunController:initialize()
    table.insert(
        self.connections,
        self.tool.Equipped:Connect(function()
            self:equip()
        end)
    )
    table.insert(
        self.connections,
        self.tool.Activated:Connect(function()
            self:activate()
        end)
    )
    table.insert(
        self.connections,
        self.tool.Unequipped:Connect(function()
            self:unequip()
        end)
    )
    table.insert(
        self.connections,
        Players.LocalPlayer.Character.Torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
            if isFirstPerson() then
                if self.equipped then
                    self.viewModelController:enable()
                end
            else
                if self.equipped then
                    self.viewModelController:disable()
                end
            end
        end)
    )
    table.insert(
        self.connections,
        toolGuiController.connectTotalAmmoUpdateEvent(self.ammoType)
    )
    table.insert(
        self.connections,
        character:GetAttributeChangedSignal("isSprinting"):Connect(function()
            local isSprinting = character:GetAttribute("isSprinting")
            if self.equipped then
                if isSprinting then
                    self.canActivate = false
                    self.canReload = false
                    self.canAimDownSight = false
                    self:_aimDownSight(false)
                    self.cancelReload = true
                    self.currentCharacterAnimationController.animationTracks.reload:Stop()
                    self.viewModelController.animationController.animationTracks.reload:Stop()
                    self.currentCharacterAnimationController.animationTracks.idle:Stop()
                    self.viewModelController.animationController.animationTracks.idle:Stop()
                    self.currentCharacterAnimationController.animationTracks.sprint:Play()
                    self.viewModelController.animationController.animationTracks.sprint:Play()
                else
                    self.canActivate = true
                    self.canReload = true
                    self.canAimDownSight = true
                    self.cancelReload = false
                    self.currentCharacterAnimationController.animationTracks.idle:Play()
                    self.viewModelController.animationController.animationTracks.idle:Play()
                    self.currentCharacterAnimationController.animationTracks.sprint:Stop()
                    self.viewModelController.animationController.animationTracks.sprint:Stop()
                end
            end
        end)
    )
end

function GunController:_aimDownSight(shouldAim : boolean)
    if shouldAim then
        UserInputService.MouseIconEnabled = false
        self.aiming = true
        self.viewModelController:SetAiming(true)
        self.soundObjects.adsIn:Play()
        self.currentCharacterAnimationController.animationTracks.adsIdle:play(self.adsSpeed)
        --viewModel animations will be animated w/ CFrame
    else
        UserInputService.MouseIconEnabled = true
        self.aiming = false
        self.viewModelController:SetAiming(false)
        self.soundObjects.adsOut:Play()
        self.currentCharacterAnimationController.animationTracks.adsIdle:Stop(self.adsSpeed)
        --viewModel animations will be animated w/ CFrame
    end
end

local function findIconBasedOnAmmoType(ammoType : string)
    for _, stat in playerStatsInfo.getAmmo() do
        if stat.name == ammoType then
            return stat.icon
        end
    end
    warn(ammoType .. " is not a valid ammo type")
end

function GunController:equip()
    player.CameraMode = Enum.CameraMode.LockFirstPerson
    rev_playSound:FireServer(self.soundObjects.equip, 0, self.SFX_part)
    if isFirstPerson() then
        self.viewModelController:enable()
    else
        self.viewModelController:disable()
    end
    self.viewModelController:equipTool()
    self.equipped = true
    self.currentPlayer = Players.LocalPlayer
    self.currentCharacter = self.currentPlayer.Character
    table.insert(
        self.connections,
        self.currentCharacter.Humanoid.Died:Connect(function()
            self:unequip()
        end)
    )
    if self.currentCharacter:GetAttribute(string.gsub(self.tool.Name, " ", "") .. "AnimsLoaded") == nil then
		self.currentCharacter:SetAttribute(string.gsub(self.tool.Name, " ", "") .. "AnimsLoaded", true)
		self.currentCharacterAnimationController = AnimationController.new(self.currentCharacter:FindFirstChild("Animator", true), self.animObjects)
	end
    self.currentPlayer:GetMouse().Icon = self.tool:GetAttribute("Cursor")

    self.currentCharacterAnimationController.animationTracks.equip:Play()
    self.viewModelController.animationController.animationTracks.equip:Play()
    self.currentCharacterAnimationController.animationTracks.equip.Stopped:Wait()
    if self.equipped then --checking this because during the equip animation, players can unequip the tool, causing a bug
        toolGuiController.setNameLabel(self.name)
        toolGuiController.setCurrentAmmoLabels(self.currentAmmo, self.MAX_MAG_AMMO)
        toolGuiController.setTotalAmmoLabel(player:GetAttribute(self.ammoType))
        toolGuiController.setAmmoIcon(findIconBasedOnAmmoType(self.ammoType))
        toolGuiController.setGuiEnabled(true)
        self.equipped = true
        self.viewModelController.toolEquipped = true
        ContextActionService:BindAction(Constants.ACTION_DROP_TOOL, function(actionName, inputState, _inputObject)
            if actionName == Constants.ACTION_DROP_TOOL and inputState == Enum.UserInputState.Begin then
                self:unequip()
                rev_droppedTool:FireServer(self.tool)
            end
        end, true, Constants.KEYBOARD_DROP_TOOL_KEY_CODE)
        local function handleAction(actionName, inputState, _inputObject)
            if actionName == Constants.ACTION_RELOAD and inputState == Enum.UserInputState.Begin then
                if self.canReload == false then return end
                if player:GetAttribute(self.ammoType) <= 0 or self.currentAmmo >= self.MAX_MAG_AMMO then
                    return
                else
                    self.reloading = true
                    if self.aiming then
                        self:_aimDownSight(false)
                    end
                    ContextActionService:UnbindAction(Constants.ACTION_RELOAD)
                    local connection
                    connection = self.currentCharacterAnimationController.animationTracks.reload:GetMarkerReachedSignal("Sound"):Connect(function(param)
                        local sound = self.soundObjects[param]
                        if sound then
                            rev_playSound:FireServer(sound, 0, self.SFX_part)
                        end
                    end)
                    self.currentCharacterAnimationController.animationTracks.reload:Play()
                    self.viewModelController.animationController.animationTracks.reload:Play()
                    self.currentCharacterAnimationController.animationTracks.reload.Stopped:Wait()
                    connection:Disconnect()
                    if self.equipped and not self.cancelReload then
                        local ammoNeededForFull = self.MAX_MAG_AMMO - self.currentAmmo
                        if player:GetAttribute(self.ammoType) >= ammoNeededForFull then
                            self.currentAmmo += ammoNeededForFull

                            --ammo attribute is also set on the client to avoid delay when getting the attribute for updating the ammo labels
                            rev_updateAmmoAttribute:FireServer(player, self.ammoType, player:GetAttribute(self.ammoType) - ammoNeededForFull)
                            player:SetAttribute(self.ammoType, player:GetAttribute(self.ammoType) - ammoNeededForFull)
                        else
                            self.currentAmmo += player:GetAttribute(self.ammoType)

                            --ammo attribute is also set on the client to avoid delay when getting the attribute for updating the ammo labels
                            player:SetAttribute(self.ammoType, 0)
                            rev_updateAmmoAttribute:FireServer(player, self.ammoType, 0)
                        end
                        toolGuiController.setCurrentAmmoLabels(self.currentAmmo, self.MAX_MAG_AMMO)
                    end
                    ContextActionService:BindAction(Constants.ACTION_RELOAD, handleAction, true, Constants.KEYBOARD_RELOAD_KEY_CODE)
                    self.reloading = false
                end
            elseif actionName == Constants.ACTION_AIM_DOWN_SIGHT then
                if not self.canAimDownSight then return end
                if inputState == Enum.UserInputState.End or self.reloading then
                    self:_aimDownSight(false)
                elseif inputState == Enum.UserInputState.Begin then
                    self:_aimDownSight(true)
                end
            end
        end

        ContextActionService:BindAction(Constants.ACTION_RELOAD, handleAction, true, Constants.KEYBOARD_RELOAD_KEY_CODE)
        ContextActionService:BindAction(Constants.ACTION_AIM_DOWN_SIGHT, handleAction, true, Enum.UserInputType.MouseButton2)
        if not character:GetAttribute("isSprinting") then
            self.canActivate = true
            self.canAimDownSight = true
            self.canReload = true
            self.currentCharacterAnimationController.animationTracks.idle:Play()
            self.viewModelController.animationController.animationTracks.idle:Play()
        else
            self.currentCharacterAnimationController.animationTracks.sprint:Play()
            self.viewModelController.animationController.animationTracks.sprint:Play()
        end
    end
end

--[[ local functions for debugging raycast
local function visualizeRay(originPosition : Vector3, endPosition : Vector3)
    local distance = (endPosition - originPosition).Magnitude
    local p = Instance.new("Part")
    p.Anchored = true
    p.CanCollide = false
    p.Size = Vector3.new(0.1, 0.1, distance)
    p.Color = Color3.new(0, 1, 0)
    p.CFrame = CFrame.lookAt(originPosition, endPosition)*CFrame.new(0, 0, -distance/2)
    p.Parent = workspace
end

local function visualizePosition(position : Vector3)
    local y = Instance.new("Part")
    y.Size = Vector3.new(0.5, 0.5, 0.5)
    y.Anchored = true
    y.Color = Color3.new(1, 0, 0)
    y.Position = position
    y.Parent = workspace
end
]]

function GunController:castRay()
    local raycastParams = RaycastParams.new()
    for _, v in self.currentCharacter:GetDescendants() do
        if v:IsA("BasePart") then
            table.insert(self.blacklistedParts, v)
        end
    end
    for _, v in self.viewModelController.viewModel:GetDescendants() do
        if v:IsA("BasePart") then
            table.insert(self.blacklistedParts, v)
        end
    end
    for _, v in workspace:FindFirstChild("Zones", true):GetDescendants() do
        if v:IsA("BasePart") then
            table.insert(self.blacklistedParts, v)
        end
    end
    raycastParams.FilterDescendantsInstances = self.blacklistedParts
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local vmMuzzle = self.viewModelController:getMuzzle()

    local rayMaxDistance = 500
    local originPosition = vmMuzzle.Position
    local targetPosition = (workspace.CurrentCamera.CFrame * CFrame.new(Vector3.new(0, 0, -rayMaxDistance))).Position
    local rayDirection = (targetPosition - originPosition).Unit * rayMaxDistance

    local raycastResult = workspace:Raycast(originPosition, rayDirection, raycastParams)

    if raycastResult.Instance.Parent:IsA("Accessory") then
        table.insert(self.blacklistedParts, raycastResult.Instance)
        raycastParams.FilterDescendantsInstances = self.blacklistedParts
        --print("recursion 2")
        return self:castRay()
    else
        --adding effects to the raycast, or if that doesn't exist, the startPosition and offset from such in the case that nothing is hit
        local hitPosition = if raycastResult then raycastResult.Position else CFrame.new(originPosition + rayDirection).Position
        createBulletEffects(vmMuzzle, hitPosition, raycastResult)

        return raycastResult, hitPosition
    end
end

function GunController:activate()
    if self.canActivate and not self.reloading then
        if self.currentAmmo <= 0 then
            rev_playSound:FireServer(self.soundObjects.dryFire, 0, self.SFX_part)
        else
            self.canActivate = false

            if self.aiming then
                --play ADS fire animation
                self.currentCharacterAnimationController.animationTracks.adsFire:Play()
                self.viewModelController.animationController.animationTracks.viewModelFire:Play()
            else
                --play hipfire animation
                self.currentCharacterAnimationController.animationTracks.hipfire:Play()
                self.viewModelController.animationController.animationTracks.hipfire:Play()
            end
    
            rev_playSound:FireServer(self.soundObjects.fire, 0, self.SFX_part)
    
            local raycastResult, hitPosition = self:castRay()
            local humanoidToDamage
            local impactSoundsArray
            local isHeadshot
            if raycastResult then
                local humanoid = raycastResult.Instance.Parent:FindFirstChild("Humanoid")
                if humanoid then
                    impactSoundsArray = self.soundObjects.fleshImpact:GetChildren()
                    if raycastResult.Instance.Name == "Head" then
                        isHeadshot = true
                    else
                        isHeadshot = false
                    end
                    humanoidToDamage = humanoid
                    indicateDamageToDealer(humanoid, raycastResult, if isHeadshot then self.damage*2 else self.damage, isHeadshot)
                else
                    impactSoundsArray = self.soundObjects.hardImpact:GetChildren()
                end
                local randomIndex = math.random(1, #impactSoundsArray)
                local randomSound = impactSoundsArray[randomIndex]
                rev_playSound:FireServer(randomSound, 0, hitPosition)
                rev_shoot:FireServer(humanoidToDamage, self.damage, isHeadshot, self.tool:FindFirstChild("Muzzle"), hitPosition, raycastResult)
            end
    
            self.currentAmmo -= 1
            toolGuiController.setCurrentAmmoLabels(self.currentAmmo, self.MAX_MAG_AMMO)
            task.wait(self.cooldown)
            if self.equipped then
                self.canActivate = true
            end
        end
	end
end

function GunController:unequip()
    --print("unequipping")
    rev_updateAmmoAttribute:FireServer(self.tool, "ammo_current", self.currentAmmo)
    toolGuiController.setGuiEnabled(false)
    player.CameraMode = Enum.CameraMode.Classic
    self:_aimDownSight(false)
    self.equipped = false
    self.viewModelController.toolEquipped = false
    self.viewModelController:disable()
    self.viewModelController:unequipTool()

    self.equipped = false
    ContextActionService:UnbindAction(Constants.ACTION_DROP_TOOL)
    ContextActionService:UnbindAction(Constants.ACTION_RELOAD)
    ContextActionService:UnbindAction(Constants.ACTION_AIM_DOWN_SIGHT)
	self.currentPlayer:GetMouse().Icon = ""
	self.canActivate = false
    self.canAimDownSight = false
    self.canReload = false
	for _, animTrack : AnimationTrack in self.currentCharacter.Humanoid.Animator:GetPlayingAnimationTracks() do
		for _, anim : Animation in self.animObjects do
            if animTrack.Animation == anim then
                animTrack:Stop()
            end
        end
	end
    self.viewModelController:stopAllViewModelAnimations()
	self.currentCharacterAnimationController:destroy()
	self.currentCharacter:SetAttribute(string.gsub(self.tool.Name, " ", "") .. "AnimsLoaded", nil)
end

function GunController:destroy()
    for _, connection in self.connections do
        connection:Disconnect()
        connection = nil
    end
    table.clear(self.connections)
    table.clear(self)
end

return GunController