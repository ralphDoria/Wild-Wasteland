local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    ACTION_DROP_TOOL = "Dropped"
}

local RaycastHitbox = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("RaycastHitboxV4"))
local AnimationController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("AnimationController"))
local ViewModelController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("ViewModelController"))

local remotes : Folder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("Remotes")
local rev_playSound : RemoteEvent = remotes:WaitForChild("PlaySound")
local rev_droppedTool : RemoteEvent = remotes:WaitForChild("DroppedTool")
local rev_hit : RemoteEvent = remotes:WaitForChild("Hit")
local rev_activate : RemoteEvent = remotes:WaitForChild("Activate")

local function isFirstPerson()
    return Players.LocalPlayer.Character.Torso.LocalTransparencyModifier >= 1
end

local MeleeController = {}
MeleeController.__index = MeleeController

function MeleeController.new(melee : Tool)
    local animObjects = {
        equip = melee:WaitForChild("Anims"):WaitForChild("equip"),
        idle = melee:WaitForChild("Anims"):WaitForChild("idle"),
        activate = melee:WaitForChild("Anims"):WaitForChild("activate")
    }
    local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    local hrp = character.HumanoidRootPart
    local newHitbox = RaycastHitbox.new(melee:WaitForChild("Hitbox"))
    newHitbox.DetectionMode = RaycastHitbox.DetectionMode.Default

    local self = {
        tool = melee,
        hitboxController = newHitbox,
        animObjects = animObjects,
        currentCharacterAnimationController = nil,
        currentPlayer = nil,
        currentCharacter = nil,
        SFX_part = melee:WaitForChild("SFX_part"),
        soundObjects = {
            equip = melee:WaitForChild("SFX_part"):WaitForChild("Shing Ringy 2 (SFX)"),
	        activate = melee:WaitForChild("SFX_part"):WaitForChild("Sword Swing Metal Heavy"),
            hit = melee:WaitForChild("SFX_part"):WaitForChild("Sword Hit (Impact)")
        },
        viewModelController = ViewModelController.new(workspace.CurrentCamera:WaitForChild("viewModel"), melee, animObjects, hrp),
        canActivate = false,
        equipped = false,
        connections = {}
    }
    setmetatable(self, MeleeController)
    self:initialize()
    return self
end

function MeleeController:initialize()
    self.hitboxController.OnHit:Connect(function(hit, humanoid, raycastResult : RaycastResult)
        if humanoid.Parent.Name ~= self.currentCharacter.Name then
            rev_hit:FireServer(self.tool, humanoid, self.soundObjects.hit, CFrame.new(raycastResult.Position, raycastResult.Normal))
        end
    end)

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

function MeleeController:equip()
    if isFirstPerson() then
        self.viewModelController:enable()
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
        end, true, Enum.KeyCode.X)
        self.currentCharacterAnimationController.animationTracks.idle:Play()
        self.viewModelController.animationController.animationTracks.idle:Play()
        self.canActivate = true
    end
end

function MeleeController:activate()
    if self.canActivate then
		self.canActivate = false
		self.currentCharacterAnimationController.animationTracks.activate:Play()
        self.viewModelController.animationController.animationTracks.activate:Play()
		self.currentCharacterAnimationController.animationTracks.activate:GetMarkerReachedSignal("ForwardSwing"):Once(function()
			self.hitboxController:HitStart()
            rev_activate:FireServer(self.tool, true, self.soundObjects.activate, 0, self.SFX_part)
		end)
		self.currentCharacterAnimationController.animationTracks.activate:GetMarkerReachedSignal("EndSwing"):Once(function()
			self.hitboxController:HitStop()
		    rev_activate:FireServer(self.tool, false)
		end)
		self.currentCharacterAnimationController.animationTracks.activate.Stopped:Wait()
		if self.equipped then
			self.canActivate = true
		end
	end
end

function MeleeController:unequip()
    self.equipped = false
    self.viewModelController.toolEquipped = false
    rev_activate:FireServer(self.tool, false) --for safety
    self.viewModelController:disable()
    self.viewModelController:unequipTool()

    self.equipped = false
    ContextActionService:UnbindAction(Constants.ACTION_DROP_TOOL)
	self.currentPlayer:GetMouse().Icon = ""
	self.canActivate = false
	self.hitboxController:HitStop() --this turns off the raycast just in case the player unequips mid swing
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

function MeleeController:destroy()

end

return MeleeController