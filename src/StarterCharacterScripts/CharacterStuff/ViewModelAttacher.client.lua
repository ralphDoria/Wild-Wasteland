local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local vmController = ReplicatedStorage:WaitForChild("RojoManaged_RS"):FindFirstChild("ViewModelController", true)
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rfn_getShirtTemplateId : RemoteFunction = ReplicatedStorage:WaitForChild("getShirtTemplateId")

repeat
    --print("waiting for appearance to load")
    task.wait()
until player:HasAppearanceLoaded()

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

local hrp = character.HumanoidRootPart

local visualizer = Instance.new("Part")
visualizer.Size = Vector3.new (0.1, 0.1, 0.1)
visualizer.Transparency = 0.5
visualizer.BrickColor = BrickColor.new("Really red")
visualizer.Anchored = true
visualizer.CanCollide = false
--visualizer.Parent = workspace

local function isFirstPerson()
    --return (character.Head.Position - camera.CFrame.Position).Magnitude < 1 --(this is unreliable because of camera sway)
    return character.Head.LocalTransparencyModifier == 1
end
local function changeViewModelTransparency(newTransparency : number)
    for _, v in viewModel:GetDescendants() do
        if v:IsA("BasePart") then
            v.LocalTransparencyModifier = newTransparency
        end
    end
end
local function reactToCameraViewChange()
    local firstPerson = isFirstPerson()
    --print("first person: " .. tostring(firstPerson))
    if firstPerson then
        changeViewModelTransparency(0)
    else
        changeViewModelTransparency(1)
    end
end
--initially hide the viewModel if player is in first person
reactToCameraViewChange()

RunService:BindToRenderStep("ViewModel", 200, function(dt)
    reactToCameraViewChange()
    head.CFrame = camera.CFrame
end)

--[[for debugging
local BodyAttachJoint = viewModel:FindFirstChild("BodyAttachJoint", true)
BodyAttachJoint:GetPropertyChangedSignal("Part1"):Connect(function()
    local bodyAttach = BodyAttachJoint.Part1
    print(if bodyAttach then bodyAttach.Parent else "nil")
end)    
]]

character:WaitForChild("Humanoid").Died:Connect(function()
    RunService:UnbindFromRenderStep("ViewModel")
    repeat task.wait() until character:FindFirstChildOfClass("Tool") == nil
    viewModel:Destroy()
end)