local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local vmController = ReplicatedStorage:WaitForChild("RojoManaged_RS"):FindFirstChild("ViewModelController", true)
local camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local rfn_getShirtTemplateId : RemoteFunction = ReplicatedStorage:WaitForChild("getShirtTemplateId")

local accessoryEffects = {}
local function updateAccessoryEffects()
    local temp = {}
    for _, v in character:GetChildren() do
        if v:IsA("Accessory") then
            for _, j in v:GetDescendants() do
                if j:IsA("ParticleEmitter") or j:IsA("Fire") then
                    local info = {
                        instance = j,
                        savedTransparency = j.Transparency
                    }
                    table.insert(temp, info)
                end
            end
        end
    end
    return temp
end
local function toggleAccessoryEffects(toggle : boolean)
    if #accessoryEffects == 0 then
        warn("no accessory particles found")
    end
    for _, v in accessoryEffects do
        if toggle then
            v.instance.Transparency = v.savedTransparency
        else
            v.instance.Transparency = NumberSequence.new(1)
        end
    end
end

repeat
    print("waiting for appearance to load")
    task.wait()
until player:HasAppearanceLoaded()

accessoryEffects = updateAccessoryEffects()

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
local hrp = character.HumanoidRootPart

local visualizer = Instance.new("Part")
visualizer.Size = Vector3.new (0.1, 0.1, 0.1)
visualizer.Transparency = 0.5
visualizer.BrickColor = BrickColor.new("Really red")
visualizer.Anchored = true
visualizer.CanCollide = false
visualizer.Parent = workspace

local function isFirstPerson()
    local artificialHeadPosition = (hrp.Position + Vector3.new(0, 1.5, 0))
    visualizer.Position = artificialHeadPosition
    local distance = (artificialHeadPosition - camera.CFrame.Position).Magnitude
    return distance < 1.1, distance
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
    toggleAccessoryEffects(not firstPerson)
    if firstPerson then
        changeViewModelTransparency(0)
    else
        changeViewModelTransparency(1)
    end
end
--initially hide the viewModel if player is in first person
reactToCameraViewChange()

RunService:BindToRenderStep("ViewModel", 200, function(dt)
    local _, distance = isFirstPerson()
    print(distance)
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