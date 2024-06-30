local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local vmController = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("ViewModelController")
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidDescription : HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
local rfn_getShirtTemplateId : RemoteFunction = ReplicatedStorage:WaitForChild("getShirtTemplateId")


--Replicating player's appearance onto view model
local viewModel = ReplicatedStorage:WaitForChild("viewModel"):Clone()
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

viewModel.Parent = camera

local torso = character.Torso

local function isFirstPerson()
    return torso.LocalTransparencyModifier >= 1
end

local function changeViewModelTransparency(newTransparency : number)
    for _, v in viewModel:GetDescendants() do
        if v:IsA("BasePart") then
            v.LocalTransparencyModifier = newTransparency
        end
    end
end

--initially hide the viewModel if player is in first person
if isFirstPerson() then
    --print("first person")
    changeViewModelTransparency(0)
else
    --print("not first person")
    changeViewModelTransparency(1)
end

--shows the view model in first person and hides it in third person
torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
    if isFirstPerson() then
        --print("first person")
        changeViewModelTransparency(0)
    else
        --print("not first person")
        changeViewModelTransparency(1)
    end
end)


RunService:BindToRenderStep("ViewModel", 200, function(dt)
    head.CFrame = camera.CFrame * CFrame.new(Vector3.new(0, 0, -1))-- * CFrame.new(Vector3.new(0, 0, -5)) * CFrame.Angles(0, math.rad(180), 0)
end)