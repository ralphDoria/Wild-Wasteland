local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local vmController = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("ViewModelController")
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rfn_getShirtTemplateId : RemoteFunction = ReplicatedStorage:WaitForChild("getShirtTemplateId")

local viewModel = ReplicatedStorage:WaitForChild("viewModel"):Clone()
local IdValid, IdNotValid = pcall(function()
    game.Players:GetNameFromUserIdAsync(player.UserId)
 end)
 if IdValid then
    local humanoidDescription : HumanoidDescription = Players:GetHumanoidDescriptionFromUserId(player.UserId)
    --Replicating player's appearance onto view model
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
else
    --While playtesting in studio with multiple players using the "TEST" tab, I was getting invalid UserId's because these are test players
    --the viewmodel will just look grey
 end

local head = viewModel:WaitForChild("Head")

--[[
    One of the parts of the viewmodel has to be anchored in order to keep the muzzle position accurate & consistent for raycasting. Otherwise,
    this bug will occur:
    https://devforum.roblox.com/t/parts-position-isnt-accurate-until-i-switch-from-server-back-to-client-in-roblox-studio-playtest/3059509
]]
if head.Anchored == false then
    head.Anchored = true
end

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
    changeViewModelTransparency(0)
else
    changeViewModelTransparency(1)
end

--shows the view model in first person and hides it in third person
torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
    if isFirstPerson() then
        changeViewModelTransparency(0)
    else
        changeViewModelTransparency(1)
    end
end)

RunService:BindToRenderStep("ViewModel", 200, function(dt)
    head.CFrame = camera.CFrame
end)

character:WaitForChild("Humanoid").Died:Connect(function()
    RunService:UnbindFromRenderStep("ViewModel")
    Debris:AddItem(viewModel, Players.RespawnTime)
    script:Destroy() --this implicitly happens since this LocalScript is located in the Character, but this line of code is here for readability
end)