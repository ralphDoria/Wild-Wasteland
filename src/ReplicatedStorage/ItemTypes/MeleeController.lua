local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    ACTION_DROP_TOOL = "Dropped"
}

local RaycastHitbox = require(ReplicatedStorage:FindFirstChild("RaycastHitboxV4", true))
local AnimationController = require(ReplicatedStorage:FindFirstChild("AnimationController", true))
local ViewModelController = require(ReplicatedStorage:FindFirstChild("ViewModelController", true))

local indicateDamageToDealer = require(ReplicatedStorage.RojoManaged_RS.Utility.indicateDamageToDealer)
local createImpactEffects = require(ReplicatedStorage:FindFirstChild("createImpactEffects", true))

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
    local hrp = character:WaitForChild("HumanoidRootPart")
    local newHitbox = RaycastHitbox.new(melee:WaitForChild("Hitbox"))
    newHitbox.DetectionMode = RaycastHitbox.DetectionMode.PartMode

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
            impactSounds = melee:WaitForChild("SFX_part").impactSounds
        },
        viewModelController = ViewModelController.new(workspace.CurrentCamera:WaitForChild("viewModel"), melee, animObjects, hrp),
        canActivate = false,
        equipped = false,
        damage = melee:GetAttribute("Damage"),
        connections = {}
    }
    setmetatable(self, MeleeController)
    self:initialize()
    return self
end

function MeleeController:initialize()
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
        self.hitboxController.OnHit:Connect(function(hit, humVarNilDueToDetectionMode, raycastResult : RaycastResult)
            local isToolPart = hit:FindFirstAncestorOfClass("Tool") ~= nil
            local isOwnLimb = hit.Parent.Name == player.Name
            if not isToolPart and not isOwnLimb then
                if raycastResult then
                    local humanoid = raycastResult.Instance.Parent:FindFirstChild("Humanoid")
                    if humanoid then
                        rev_playSound:FireServer(self.soundObjects.impactSounds:WaitForChild("flesh"), raycastResult.Position, 0.2)
                        indicateDamageToDealer(humanoid, raycastResult, self.damage)
                    else
                        if raycastResult.Material == Enum.Material.Ground 
                        or raycastResult.Material == Enum.Material.Grass
                        or raycastResult.Material == Enum.Material.Sand
                        or raycastResult.Material == Enum.Material.Snow then
                            rev_playSound:FireServer(self.soundObjects.impactSounds:WaitForChild("dirt"), raycastResult.Position, 0)
                        else
                            rev_playSound:FireServer(self.soundObjects.impactSounds:WaitForChild("Axe Impact Giant Thuddy Hits On Wood Floor 1 (SFX)"), raycastResult.Position, 0)
                        end
                    end
                    
                    local castResultInfo = {
                        Normal = raycastResult.Normal,
                        hitHumanoid = if humanoid then true else false,
                        Material = raycastResult.Material 
                    }
                    rev_hit:FireServer(self.tool, humanoid, raycastResult.Position, castResultInfo)
                    createImpactEffects(raycastResult.Position, castResultInfo)
                end
            end
        end)
    )
end

function MeleeController:equip()
    if isFirstPerson() then
        self.viewModelController:enable()
    else
        self.viewModelController:disable()
    end
    self.viewModelController:equipTool()

    rev_playSound:FireServer(self.soundObjects.equip, self.SFX_part, 0)
    self.equipped = true
    self.currentPlayer = player
    self.currentCharacter = player.Character
    local diedConnection
    diedConnection = self.currentCharacter.Humanoid.Died:Connect(function()
        self:unequip()
        rev_droppedTool:FireServer(self.tool)
    end)
    self.tool:GetPropertyChangedSignal("Parent"):Once(function()
        local toolWasUnequipped = self.tool.Parent ~= self.currentCharacter
        if toolWasUnequipped then
            diedConnection:Disconnect()
        end
    end)
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