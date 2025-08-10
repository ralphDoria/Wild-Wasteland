local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
local SoundService = game:GetService("SoundService")
ReplicatedFirst:RemoveDefaultLoadingScreen()

--***************Loading Screen intial business to stand on, yfm????
local ScreenGui_LoadingScreen = ReplicatedFirst:WaitForChild("LoadingScreen"):: ScreenGui
local player = game:GetService("Players").LocalPlayer
local playerGui = player:WaitForChild("PlayerGui"):: PlayerGui
ScreenGui_LoadingScreen.Enabled = true
ScreenGui_LoadingScreen.Parent = playerGui

--***************Loading Screen Initial Instances
local Sound = ScreenGui_LoadingScreen:WaitForChild("Sound"):: Sound

local _frame = ScreenGui_LoadingScreen:WaitForChild("Frame"):: Frame
local _canvasGroup = _frame:WaitForChild("CanvasGroup"):: CanvasGroup
local MessageTxtLbl: TextLabel = _canvasGroup:WaitForChild("Message")
local _folder = _canvasGroup:WaitForChild("Folder")
local RadiationSymbol = _folder:WaitForChild("LoadingIcon"):WaitForChild("RadiationSymbol"):: ImageLabel
local Percentage = _folder:WaitForChild("Percentage"):: TextLabel
local LoadingDisplay = _folder:WaitForChild("LoadingDisplay"):: TextLabel
local Timer = _folder:WaitForChild("Timer"):: TextLabel

local Components = ReplicatedFirst:WaitForChild("RojoManaged_RF"):WaitForChild("LoadingScreenScripts"):WaitForChild("Components")
local AssetsToPreload = {
    RadiationSymbol,
    Sound
}
local Messages = require("./Components/LoadingScreenMessages")
local TextManager = require("./Components/TextManager")
TextManager.init(Percentage, Timer, MessageTxtLbl)

local stopTimer: boolean = false
local function startTimer(callback: (elapsedTime: number) -> ())
    local elapsedTime = 0
    task.spawn(function()
        while stopTimer == false do
            task.wait(1)
            elapsedTime += 1
            callback(elapsedTime)
        end
    end)
end

local stopDisplayingMessages = false
local function startDisplayingRandomMessages()
    task.spawn(function()
        while not stopDisplayingMessages do
            local currentMessage = MessageTxtLbl.Text
            local randomMessage: string = Messages[math.random(1, #Messages)]
            repeat
                randomMessage = Messages[math.random(1, #Messages)]
            until randomMessage ~= currentMessage 
            TextManager.setDisplayMessage(randomMessage)
            local wordCount: number = #randomMessage:split(" ")
            task.wait(wordCount*0.4)
        end
    end)
end

local function disableSelectCoreUisAndTouchControls()
    GuiService.TouchControlsEnabled = false
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) 
    -- Disables the Reset Button
    ----[ Creates a Loop to make sure that the ResetButtonCallBack works.
    local disableResetButton = task.spawn(function()
        repeat 
            local success = pcall(function() 
                StarterGui:SetCore("ResetButtonCallback", false) 
            end)
            task.wait(1)
        until success
    end)
end

local function StartPreload()
    RadiationSymbol.Rotation = -180
    TweenService:Create(RadiationSymbol, TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge, false), {Rotation = 180}):Play()

    startTimer(function(elapsedTime: number)  
        TextManager.setDisplayTime(elapsedTime) 
    end)

    startDisplayingRandomMessages()

    local maxAssets: number = #AssetsToPreload
    local assetsLoaded: number = 0

    Sound:Play()
    disableSelectCoreUisAndTouchControls()
        
    ContentProvider:PreloadAsync(AssetsToPreload, function(assetId, assetFetchStatus): ...any  
        warn(`Preloading: {assetId} | {assetFetchStatus}`)
        if assetFetchStatus == Enum.AssetFetchStatus.Success then
            assetsLoaded += 1
            TextManager.setDisplayPercentage(assetsLoaded/maxAssets*100)
        end
    end) 

    ScreenGui_LoadingScreen:SetAttribute("PreloadingFinished", true)
    LoadingDisplay.Text = "Wild Wasteland has Loaded"
    LoadingDisplay.TextColor3 = Color3.fromRGB(0, 255, 0)
    Timer.TextColor3 = Color3.fromRGB(0, 255, 0)
    Percentage.TextColor3 = Color3.fromRGB(0, 255, 0)
    stopTimer = true
end

local LoadingScreen = {}

function LoadingScreen.init()
    SoundService.ChildAdded:Connect(function(child)
        if child:IsA("SoundGroup") then
            child.Volume = 0
        end
    end)

    StartPreload()
    LoadingScreen.transitionOut()
end

function LoadingScreen.transitionOut()
    stopDisplayingMessages = true
    local fadeOutTween = TweenService:Create(_canvasGroup, TweenInfo.new(1), {GroupTransparency = 1})
    fadeOutTween:Play()
    fadeOutTween.Completed:Wait()
    GuiService.TouchControlsEnabled = true
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
    Sound:Stop()
end

function LoadingScreen.Destroy()
    ScreenGui_LoadingScreen:Destroy()
end

return LoadingScreen