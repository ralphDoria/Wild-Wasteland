local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local vmController = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("viewModelController")
local camera = workspace.CurrentCamera

local viewModel = ReplicatedStorage:WaitForChild("viewModel"):Clone()
viewModel.Parent = camera

local function setCanCollideOffForModel(model : Model)
    for _, v in model:GetChildren() do
        if v:IsA("BasePart") then
            v.CanCollide = false
        end
    end
end

--[[
RunService.RenderStepped:Connect(function(dt)
    setCanCollideOffForModel(viewModel)
    viewModel.Head.CFrame = camera.CFrame
end)
]]

RunService:BindToRenderStep("viewModel", 200, function(dt)
    setCanCollideOffForModel(viewModel)
    viewModel.Head.CFrame = camera.CFrame
end)

--RunService:UnbindFromRenderStep("viewModel")

--local vmc = vmController.new(viewModel)