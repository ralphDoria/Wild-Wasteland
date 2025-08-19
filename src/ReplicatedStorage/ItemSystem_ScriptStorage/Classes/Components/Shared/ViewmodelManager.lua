--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local ToolAnimationManager = require("./ToolAnimationManager")
local Spring = require(ReplicatedStorage.Packages.Spring)
local stride = 0
local bobbing = 0

export type ViewmodelManager = {
    viewmodel : Model,
    ToolToVMToolMapping : { [Tool] : Tool },
    toolAnimationManagerObject : ToolAnimationManager.AnimationManager,
    connections : {[Tool | string]: {[string]: RBXScriptConnection}},
    mouseSway : any
}

local ViewmodelManager = {}

function ViewmodelManager.new(viewmodel: Model) : ViewmodelManager
    local self : ViewmodelManager = {
        viewmodel = viewmodel,
        ToolToVMToolMapping = {},
        toolAnimationManagerObject = ToolAnimationManager.new(viewmodel),
        connections = {},
        mouseSway = Spring.new(Vector3.new())
    }

    self.mouseSway.Speed = 10
    self.mouseSway.Damper = 1

    ViewmodelManager._initialize(self)
    return self
end

function ViewmodelManager.AddTool(self: ViewmodelManager, tool: Tool, animations : {[string] : Animation})
    local vmTool = tool:Clone()
    vmTool:AddTag("vmTool")
    local vmToolModel = vmTool:WaitForChild("ToolModel") :: Model | MeshPart
    if vmToolModel:IsA("MeshPart") then
        vmToolModel.CanCollide = false
    elseif vmToolModel:IsA("Model") then
        for _, v in vmToolModel:GetDescendants() do
            if v:IsA("BasePart") then
                v.CanCollide = false
            end
        end
    end
    vmTool.Parent = nil
    self.ToolToVMToolMapping[tool] = vmTool
    ToolAnimationManager.LoadAnimations(self.toolAnimationManagerObject, tool, animations)
    self.connections[tool] = {}
    self.connections[tool].equipped = tool.Equipped:Connect(function()
        ViewmodelManager.toggleViewmodelToolVisibility(self, tool)
        ViewmodelManager._toggleBobAndSway(self, true)
        vmTool.Parent = self.viewmodel
        local BodyAttachJoint = self.viewmodel:WaitForChild("Torso"):FindFirstChild("BodyAttachJoint") :: Motor6D
        if BodyAttachJoint then
            BodyAttachJoint.Part1 = vmTool:FindFirstChild("BodyAttach", true) :: BasePart
        end
    end)
    self.connections[tool].unequipped = tool.Unequipped:Connect(function()
        ViewmodelManager._toggleBobAndSway(self, false)
        vmTool.Parent = nil
        local BodyAttachJoint = self.viewmodel:WaitForChild("Torso"):FindFirstChild("BodyAttachJoint") :: Motor6D
        if BodyAttachJoint then
            BodyAttachJoint.Part1 = nil
        end
    end)
    -- for i, v in tool:GetDescendants() do
    --     if v:IsA("BasePart") then
    --         self.connections[tool]["transparencyMatcher" .. i] = v:GetPropertyChangedSignal("Transparency"):Connect(function(...: any)
    --             local corresponding = vmTool:FindFirstChild(v.Name, true):: BasePart
    --             if corresponding then
    --                 corresponding.Transparency = v.Transparency  
    --             end
    --         end)
    --     end
    -- end
end

function ViewmodelManager.removeTool(self: ViewmodelManager, tool: Tool)
    ToolAnimationManager.RemoveTool(self.toolAnimationManagerObject, tool)
    self.ToolToVMToolMapping[tool]:Destroy()
    self.ToolToVMToolMapping[tool] = nil
    for _, connection in self.connections[tool] do
        connection:Disconnect()
    end
    table.clear(self.connections[tool])
end

function ViewmodelManager.findOriginalTool(self: ViewmodelManager,vmTool: Tool): Tool?
    for key, v in self.ToolToVMToolMapping do
        if v == vmTool then
            return key
        end
    end
    return nil
end

function ViewmodelManager._initialize(self : ViewmodelManager)
    --[[
    The file named "ViewModelAttacher" makes all descendants of the viewmodel before the frame renders, while 
    the RBXScriptConnection here changes the vmTool transparency after the frame has rendered
    ]]
    self.connections.ToggleVMToolVisibilityBasedOnTorsoTransparency = Players.LocalPlayer.Character.Torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
        local equippedViewmodelTool = self.viewmodel:FindFirstChildOfClass("Tool")
        if equippedViewmodelTool then
            ViewmodelManager.toggleViewmodelToolVisibility(self, ViewmodelManager.findOriginalTool(self, equippedViewmodelTool) :: Tool) 
        end
    end)
end

function ViewmodelManager._viewmodelBobAndSwayCalculation(self: ViewmodelManager, deltaTime: number)
    local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart
    local Constants = {
        VIEW_MODEL_OFFSET = CFrame.new(0, 0, 0),
        VIEW_MODEL_BOBBING_SPEED = 0.4,
        VIEW_MODEL_BOBBING_AMOUNT = 0.05,
        VIEW_MODEL_BOBBING_TRANSITION_SPEED = 10
    }

    -- calculating bob 
    local moveSpeed = hrp.AssemblyLinearVelocity.Magnitude
    local bobbingSpeed = moveSpeed * Constants.VIEW_MODEL_BOBBING_SPEED
    local bobbing = math.min(bobbingSpeed, 1)
    stride = (stride + bobbingSpeed * deltaTime) % (math.pi * 2)
    bobbing = math.lerp(bobbing, bobbing, math.min(deltaTime * Constants.VIEW_MODEL_BOBBING_TRANSITION_SPEED, 1))
    local x = math.sin(stride)
    local y = math.sin(stride * 2)
    local bobbingOffset = Vector3.new(x, y, 0) * Constants.VIEW_MODEL_BOBBING_AMOUNT * bobbing
    local bobbingCFrame = CFrame.new(bobbingOffset)

    --calculating sway
    local mouseDelta = UserInputService:GetMouseDelta()
    self.mouseSway.Velocity += Vector3.new(mouseDelta.X/50, mouseDelta.Y/50)
    local swayCFrame = CFrame.Angles(-self.mouseSway.Position.Y, -self.mouseSway.Position.X, 0)

    --actually setting the cframe
    local vmHead = self.viewmodel:FindFirstChild("Head") :: BasePart
    vmHead.CFrame = workspace.CurrentCamera.CFrame * bobbingCFrame * swayCFrame
end

function ViewmodelManager._toggleBobAndSway(self: ViewmodelManager, toggle: boolean)
    if toggle then
        RunService:BindToRenderStep("ViewmodelBobAndSway", 200, function(dt: number)  
            ViewmodelManager._viewmodelBobAndSwayCalculation(self, dt)
        end)
    else
        RunService:UnbindFromRenderStep("ViewmodelBobAndSway")
    end
end

--[[
    This function toggles the visibility of the viewmodel tool and does the opposite for the visibility of the actual tool.
]]
function ViewmodelManager.toggleViewmodelToolVisibility(self : ViewmodelManager, tool: Tool, toggle: boolean?)
    local toolModel = tool:FindFirstChild("ToolModel") :: Model | MeshPart
    local vmToolModel = self.ToolToVMToolMapping[tool]:FindFirstChild("ToolModel") :: Model | MeshPart
    local vmToolTransparency
    local toolTransparency
    if toggle == nil then
        local isFirstPerson = Players.LocalPlayer.Character.Torso.LocalTransparencyModifier >= 1
        vmToolTransparency = if isFirstPerson then 0 else 1
        toolTransparency = if isFirstPerson then 1 else 0
    else
        vmToolTransparency = if toggle then 0 else 1
        toolTransparency = if toggle then 1 else 0
    end
    if vmToolModel:IsA("MeshPart") then
        vmToolModel.LocalTransparencyModifier = vmToolTransparency
    elseif vmToolModel:IsA("Model") then
        for _, v in vmToolModel:GetDescendants() do
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = vmToolTransparency
            end
        end
    end

    if toolModel:IsA("MeshPart") then
        toolModel.LocalTransparencyModifier = toolTransparency
    elseif toolModel:IsA("Model") then
        for _, v in toolModel:GetDescendants() do
            if v:IsA("BasePart") then
                v.LocalTransparencyModifier = toolTransparency
            end
        end
    end
end

function ViewmodelManager.Destroy(self: ViewmodelManager)
    for _, toolConnections in self.connections do
        for _, v in toolConnections do
            v:Disconnect()
        end
    end
    ToolAnimationManager.Destroy(self.toolAnimationManagerObject)
    -- Destruction of viewmmodel will happen at call site where viewmmodel was created
    -- according to ChatGPT, spring modules don't have destroy functions because you're expected to just drop its reference & have the luau GC handle it
    table.clear(self)
end

return ViewmodelManager