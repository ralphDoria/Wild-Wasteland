local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Constants = {
    KEYBOARD_DROP_TOOL_KEY_CODE = Enum.KeyCode.X,
    ACTION_DROP_TOOL = "Dropped"
}

local AnimationController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("AnimationController"))
local ViewModelController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("ViewModelController"))

local consumableRemotes : Folder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Consumable"):WaitForChild("Remotes")
local rev_playSound : RemoteEvent = consumableRemotes:WaitForChild("PlaySound")
local rev_droppedTool : RemoteEvent = consumableRemotes:WaitForChild("DroppedTool")
local rev_activate : RemoteEvent = consumableRemotes:WaitForChild("Activate")

local function isFirstPerson()
    return Players.LocalPlayer.Character.Torso.LocalTransparencyModifier >= 1
end

local ConsumableController = {}
ConsumableController.__index = ConsumableController

function ConsumableController.new(consumable : Tool)
    local animObjects = {
        equip = consumable:WaitForChild("Anims"):WaitForChild("equip"),
        idle = consumable:WaitForChild("Anims"):WaitForChild("idle"),
        activate = consumable:WaitForChild("Anims"):WaitForChild("activate")
    }
    local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")

    local self = {
        tool = consumable,
        animObjects = animObjects,
        currentCharacterAnimationController = nil,
        currentPlayer = nil,
        currentCharacter = nil,
        SFX_part = consumable:WaitForChild("SFX_part"),
        soundObjects = {
            equip = consumable:WaitForChild("SFX_part"):WaitForChild("equip"),
	        needleInsert = consumable:WaitForChild("SFX_part"):WaitForChild("needleInsert"),
            needleRemove = consumable:WaitForChild("SFX_part"):WaitForChild("needleRemove"),
            medicalInjection = consumable:WaitForChild("SFX_part"):WaitForChild("medicalInjection"),
            heartbeat = consumable:WaitForChild("SFX_part"):WaitForChild("heartbeat")
        },
        viewModelController = ViewModelController.new(workspace.CurrentCamera:WaitForChild("viewModel"), consumable, animObjects, hrp),
        canActivate = false,
        equipped = false,
        connections = {}
    }
    setmetatable(self, ConsumableController)
    self:initialize()
    return self
end

function ConsumableController:initialize()
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

function ConsumableController:equip()
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
    --self.currentPlayer:GetMouse().Icon = self.tool:GetAttribute("Cursor")

    self.currentCharacterAnimationController.animationTracks.equip:Play()
    self.viewModelController.animationController.animationTracks.equip:Play()
    self.currentCharacterAnimationController.animationTracks.equip.Stopped:Wait()
    if self.equipped then --checking this because during the equip animation, players can unequip the tool, causing a bug
        self.equipped = true
        self.viewModelController.toolEquipped = true
        ContextActionService:BindAction(Constants.ACTION_DROP_TOOL, function(actionName, inputState, _inputObject)
            if actionName == Constants.ACTION_DROP_TOOL and inputState == Enum.UserInputState.Begin then
                self:unequip()
                rev_droppedTool:FireServer(self.tool, false)
            end
        end, true, Enum.KeyCode.X)
        self.currentCharacterAnimationController.animationTracks.idle:Play()
        self.viewModelController.animationController.animationTracks.idle:Play()
        self.canActivate = true
    end
end

function ConsumableController:activate()
    if self.canActivate then
		self.canActivate = false
		self.currentCharacterAnimationController.animationTracks.activate:Play()
        self.viewModelController.animationController.animationTracks.activate:Play()
		self.currentCharacterAnimationController.animationTracks.activate:GetMarkerReachedSignal("needleInsert"):Once(function()
            rev_playSound:FireServer(self.soundObjects.needleInsert, 0, self.SFX_part)
		end)
		self.currentCharacterAnimationController.animationTracks.activate:GetMarkerReachedSignal("startInjecting"):Once(function()
		    rev_playSound:FireServer(self.soundObjects.medicalInjection, 0, self.SFX_part)
		end)
        --[[
        self.currentCharacterAnimationController.animationTracks.activate:GetMarkerReachedSignal("finishedInjecting"):Once(function()
           
		end)
        ]]
        self.currentCharacterAnimationController.animationTracks.activate:GetMarkerReachedSignal("needleRemove"):Once(function()
            self.tool.ToolModel.liquid.Transparency = 1
            self.soundObjects.heartbeat:Play()
            rev_activate:FireServer(self.tool)
		    rev_playSound:FireServer(self.soundObjects.needleRemove, 0, self.SFX_part)
            rev_droppedTool:FireServer(self.tool, true)
            self:unequip()  
		end)
		self.currentCharacterAnimationController.animationTracks.activate.Stopped:Wait()
		if self.equipped then
			self.canActivate = true
		end
	end
end

function ConsumableController:unequip()
    self.equipped = false
    self.viewModelController.toolEquipped = false
    self.viewModelController:disable()
    self.viewModelController:unequipTool()

    self.equipped = false
    ContextActionService:UnbindAction(Constants.ACTION_DROP_TOOL)
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

function ConsumableController:destroy()

end

return ConsumableController