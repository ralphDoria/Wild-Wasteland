local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local vmController = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("viewModelController")
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character
local humanoidDescription : HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
local rfn_getShirtTemplateId : RemoteFunction = ReplicatedStorage:WaitForChild("getShirtTemplateId")

local viewModel = ReplicatedStorage:WaitForChild("viewModel"):Clone()
--just in case
for _, v in viewModel:GetChildren() do
    if v:IsA("BasePart") then
        v.CollisionGroup = "viewModel"
    end
end

local bodyColors : BodyColors = Instance.new("BodyColors")
bodyColors.HeadColor3 =  humanoidDescription.HeadColor
bodyColors.RightArmColor3 = humanoidDescription.RightArmColor
bodyColors.LeftArmColor3 = humanoidDescription.LeftArmColor
bodyColors.Parent = viewModel

local playerIsWearingAShirt = humanoidDescription.Shirt ~= 0
if playerIsWearingAShirt then
    local shirt : Shirt = Instance.new("Shirt")
    local shirtTemplateId = rfn_getShirtTemplateId:InvokeServer(humanoidDescription.Shirt)
    shirt.ShirtTemplate = shirtTemplateId
    shirt.Parent = viewModel
end


local head = viewModel:WaitForChild("Head")
local torso = viewModel:WaitForChild("Torso")
local M6Ds : Motor6D = {
    rightShoulder = torso:WaitForChild("Right Shoulder"),
    leftShoulder = torso:WaitForChild("Left Shoulder")
}
local originC0 : CFrame = {
    rightShoulder = M6Ds.rightShoulder.C0,
    leftShoulder = M6Ds.leftShoulder.C0
}
viewModel.Parent = camera

--[[
RunService.RenderStepped:Connect(function(dt)
    setCanCollideOffForModel(viewModel)
    viewModel.Head.CFrame = camera.CFrame
end)
]]

RunService:BindToRenderStep("viewModel", 200, function(dt)
    head.CFrame = camera.CFrame
    M6Ds.rightShoulder.C0 = character.Torso["Right Shoulder"].C0
    M6Ds.leftShoulder.C0 = originC0.leftShoulder * CFrame.Angles(0, 0, -math.rad(90))
end)

--RunService:UnbindFromRenderStep("viewModel")

--local vmc = vmController.new(viewModel)