local Constants = {
	VIEW_MODEL_OFFSET = CFrame.new(0, 0, 0),
	VIEW_MODEL_BOBBING_SPEED = 0.4,
	VIEW_MODEL_BOBBING_AMOUNT = 0.05,
	VIEW_MODEL_BOBBING_TRANSITION_SPEED = 10
}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local SpringModule = require(ReplicatedStorage.RojoManaged_RS.SpringModule)
local lerp = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("lerp"))
local AnimationController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("AnimationController"))

local ViewModelController = {}
ViewModelController.__index = ViewModelController

function ViewModelController.new(viewModel : Model, tool : Tool, animObjects, hrp)
    local vmTool = tool:Clone()
    vmTool.Scripts:Destroy()
    vmTool.SFX_part:Destroy()
    local toolInstances = {}
    for _, v in tool:GetDescendants() do
        if v:IsA("BasePart") then
            table.insert(toolInstances, v)
        end
    end

    local self = {
        enabled = false,
        viewModel = viewModel,
        vmTool = vmTool,
        toolEquipped = false,
        toolInstances = toolInstances,
        animObjects = animObjects,
        animationController = AnimationController.new(viewModel.Humanoid.Animator, animObjects),
        stride = 0,
		bobbing = 0,
        hrp = hrp,
        aiming = false,
        aimPart = vmTool:FindFirstChild("aimPart")
    }

    return setmetatable(self, ViewModelController)
end

function ViewModelController:SetAiming(value : boolean)
    if not self.vmTool:hasTag("Gun") then
        warn("This function is only meant for the tool type of gun")
    end
    self.aiming = value
end

function ViewModelController:enable()
	self.enabled = true

    self:showViewModelTool()

    local timeAccumulated = 0
    local mouseSway = SpringModule.new(Vector3.new())
    mouseSway.Speed = 10
    mouseSway.Damper = 1

    RunService:BindToRenderStep("ViewModelTool", 200, function(deltaTime)
        local ads_CFrame = CFrame.new()
        if self.vmTool:HasTag("Gun") then
            if self.aiming then
                workspace.CurrentCamera.FieldOfView = 60
                if self.aimPart then
                    local manualOffsetCorretion = CFrame.new(0, 0.02, -1)
                    local aimPartOffsetFromCamera = (workspace.CurrentCamera.CFrame:Inverse() * self.aimPart.CFrame):Inverse()
                    ads_CFrame = aimPartOffsetFromCamera * manualOffsetCorretion
                    --[[
                    wtffffff I got this CFrame calculation with educated guessing & checking, so surprised it worked
                    ]]
                end
            else
                workspace.CurrentCamera.FieldOfView = 70
            end
        end

        -- View model bobbing procedural animation calculation
        local moveSpeed = self.hrp.AssemblyLinearVelocity.Magnitude    
        local bobbingSpeed = moveSpeed * Constants.VIEW_MODEL_BOBBING_SPEED
        local bobbing = math.min(bobbingSpeed, 1)

        self.stride = (self.stride + bobbingSpeed * deltaTime) % (math.pi * 2)
        self.bobbing = lerp(self.bobbing, bobbing, math.min(deltaTime * Constants.VIEW_MODEL_BOBBING_TRANSITION_SPEED, 1))

        local x = math.sin(self.stride)
        local y = math.sin(self.stride * 2)
        local bobbingOffset = Vector3.new(x, y, 0) * Constants.VIEW_MODEL_BOBBING_AMOUNT * self.bobbing
        local bobbingCFrame = CFrame.new(bobbingOffset)
        if self.aiming then
            bobbingCFrame = CFrame.new() --negates the bobbingCFrame if the player is aiming in
        end
        --

        --view model sway procedural animation calculation
        local mouseDelta = UserInputService:GetMouseDelta()
        mouseSway.Velocity += Vector3.new(mouseDelta.X/50, mouseDelta.Y/50)
        local swayCFrame = CFrame.Angles(-mouseSway.Position.Y, -mouseSway.Position.X, 0)
        if self.aiming then
            swayCFrame = CFrame.new() --negates the swayCFrame if the player is aiming in
        end
        --

        local viewModelInitialOffset : CFrame = CFrame.new(0, -1, 0)
        local viewModelOffset
        if not self.toolEquipped and timeAccumulated <= self.animationController.animationTracks.equip.Length then
            timeAccumulated += deltaTime
            local lerpAlpha = timeAccumulated/self.animationController.animationTracks.equip.Length
            viewModelOffset = viewModelInitialOffset:Lerp(Constants.VIEW_MODEL_OFFSET, lerpAlpha)
        else
            viewModelOffset = Constants.VIEW_MODEL_OFFSET
        end

        self.viewModel.Head.CFrame = workspace.CurrentCamera.CFrame * viewModelOffset * bobbingCFrame * swayCFrame * ads_CFrame
    end)
end

function ViewModelController:disable()
	self.enabled = false

    self:hideViewModelTool()

    RunService:UnbindFromRenderStep("ViewModelTool")
end

function ViewModelController:showViewModelTool()
    --shows view model tool
    for _, instance in self.vmTool:GetDescendants() do
        if instance:IsA("BasePart") then
            instance.LocalTransparencyModifier = 0
        end
    end
    --hides real character's tool
    for _, instance in self.toolInstances do
        instance.LocalTransparencyModifier = 1
    end 
end

function ViewModelController:hideViewModelTool()
    --hides view model tool
    for _, instance in self.vmTool:GetDescendants() do
        if instance:IsA("BasePart") then
            instance.LocalTransparencyModifier = 1
        end
    end
    --shows real character's tool
    for _, instance in self.toolInstances do
        instance.LocalTransparencyModifier = 0
    end
end

function ViewModelController:equipTool()
   self.vmTool.Parent = self.viewModel
   self.viewModel:WaitForChild("Torso").BodyAttachJoint.Part1 = self.vmTool.BodyAttach 
end

function ViewModelController:unequipTool()
    self.vmTool.Parent = nil
    self.viewModel:WaitForChild("Torso").BodyAttachJoint.Part1 = nil
end

function ViewModelController:stopAllViewModelAnimations()
    for _, animTrack : AnimationTrack in self.viewModel.Humanoid.Animator:GetPlayingAnimationTracks() do
		for _, anim : Animation in self.animObjects do
            if animTrack.Animation == anim then
                animTrack:Stop()
            end
        end
	end
end

function ViewModelController:destroy()
    table.clear(self)
    self = nil
end

return ViewModelController