local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    KEYBOARD_RELOAD_KEY_CODE = Enum.KeyCode.R,
    ACTION_DROP_TOOL = "Dropped",
    ACTION_RELOAD = "Reload"
}

local AnimationController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("AnimationController"))
local ViewModelController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("ViewModelController"))

local gunRemotes : Folder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Gun"):WaitForChild("Remotes")
local rev_playSound : RemoteEvent = gunRemotes:WaitForChild("PlaySound")
local rev_droppedTool : RemoteEvent = gunRemotes:WaitForChild("DroppedTool")
local rev_shoot : RemoteEvent = gunRemotes:WaitForChild("Shoot")
local rev_reload : RemoteEvent = gunRemotes:WaitForChild("Reload")

local function isFirstPerson()
    return Players.LocalPlayer.Character.Torso.LocalTransparencyModifier >= 1
end

local GunController = {}
GunController.__index = GunController

function GunController.new(gun : Tool)
    local animObjects = {
        equip = gun:WaitForChild("Anims"):WaitForChild("equip"),
        idle = gun:WaitForChild("Anims"):WaitForChild("idle"),
        shoot = gun:WaitForChild("Anims"):WaitForChild("shoot"),
        reload = gun:WaitForChild("Anims"):WaitForChild("reload")
    }
    local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    local self = {
        tool = gun,
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
            ["dryFire"]         = gun:WaitForChild("SFX_part"):WaitForChild("Ammo Magazine 3 (SFX) (dryfire)")

        },
        viewModelController = ViewModelController.new(workspace.CurrentCamera:WaitForChild("viewModel"), gun, animObjects, hrp),
        canActivate = false,
        equipped = false,
        reloading = false,
        connections = {}
    }
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
end

function GunController:equip()
    print("equipping")
    if isFirstPerson() then
        self.viewModelController:enable()
    else
        self.viewModelController:disable()
    end
    self.viewModelController:equipTool()

    rev_playSound:FireServer(self.soundObjects.equip, 0, self.SFX_part)
    self.equipped = true
    self.currentPlayer = Players.LocalPlayer
    self.currentCharacter = self.currentPlayer.Character
    if self.currentCharacter:GetAttribute(string.gsub(self.tool.Name, " ", "") .. "AnimsLoaded") == nil then
		self.currentCharacter:SetAttribute(string.gsub(self.tool.Name, " ", "") .. "AnimsLoaded", true)
		self.currentCharacterAnimationController = AnimationController.new(self.currentCharacter:FindFirstChild("Animator", true), self.animObjects)
	end
    self.currentPlayer:GetMouse().Icon = self.tool:GetAttribute("Cursor")

    self.currentCharacterAnimationController.animationTracks.equip:Play()
    self.viewModelController.animationController.animationTracks.equip:Play()
    self.currentCharacterAnimationController.animationTracks.equip.Stopped:Wait()
    if self.equipped then --checking this because during the equip animation, players can unequip the tool, causing a bug
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
                ContextActionService:BindAction(Constants.ACTION_RELOAD, handleAction, true, Constants.KEYBOARD_RELOAD_KEY_CODE)
            end
        end

        ContextActionService:BindAction(Constants.ACTION_RELOAD, handleAction, true, Constants.KEYBOARD_RELOAD_KEY_CODE)
        self.currentCharacterAnimationController.animationTracks.idle:Play()
        self.viewModelController.animationController.animationTracks.idle:Play()
        self.canActivate = true
    end
end

function GunController:activate()
    if self.canActivate then
		self.canActivate = false

		self.currentCharacterAnimationController.animationTracks.shoot:Play()
        self.viewModelController.animationController.animationTracks.shoot:Play()
		rev_playSound:FireServer(self.soundObjects.fire, 0, self.SFX_part)
        rev_shoot:FireServer()

		self.currentCharacterAnimationController.animationTracks.shoot.Stopped:Wait()
		if self.equipped then
			self.canActivate = true
		end

	end
end

function GunController:unequip()
    self.equipped = false
    self.viewModelController.toolEquipped = false
    self.viewModelController:disable()
    self.viewModelController:unequipTool()

    self.equipped = false
    ContextActionService:UnbindAction(Constants.ACTION_DROP_TOOL)
    ContextActionService:UnbindAction(Constants.ACTION_RELOAD)
	self.currentPlayer:GetMouse().Icon = ""
	self.canActivate = false
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

end

return GunController