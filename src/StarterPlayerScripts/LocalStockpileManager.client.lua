local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local rev_statChangeSound = ReplicatedStorage:FindFirstChild("StatChangeSound", true)

local SoundService = game:GetService("SoundService")
local coinCollectSound : Sound = SoundService.CurrencySystem["Coins ka-ching"]
local ammoCollectSound : Sound = SoundService:FindFirstChild("Ammo pickup", true)

rev_statChangeSound.OnClientEvent:Connect(function(tagName : string)
    if tagName == "DroppedCurrency" then
        playSound(coinCollectSound, nil, 0)
    elseif tagName == "DroppedAmmo" then
        playSound(ammoCollectSound, nil, 0)
    else
        warn("parameter passed does not match any existing stat name")
    end
end)

local StatsGui : ScreenGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("StatsGui")
local statsBillboard : Frame = StatsGui.Billboard
local storageButton : ImageButton = StatsGui:WaitForChild("StorageButton")
local openSize = UDim2.new(0.5, 0, 0.5, 0)
local closeSize = UDim2.new(0.5, 0, 0, 0)
local TweenService = game:GetService("TweenService")
local tweenInfo = TweenInfo.new(0.2)
local tweenOpen = TweenService:Create(statsBillboard, tweenInfo, {Size = openSize})
local tweenClose = TweenService:Create(statsBillboard, tweenInfo, {Size = closeSize})
statsBillboard.Size = closeSize
statsBillboard.Visible = false
local open = false

local ContextActionService = game:GetService("ContextActionService")
local ACTION_STATS = "changeStatsBillboardVisibility"

local function openOrCloseStatsMenu()
    if open then
        storageButton.Image = "http://www.roblox.com/asset/?id=18511847292"
        open = false
        tweenClose:Play()
        tweenClose.Completed:Wait()
        if open == false then
            statsBillboard.Visible = false 
        end
    else
        storageButton.Image = "http://www.roblox.com/asset/?id=18511845492"
        statsBillboard.Visible = true
        open = true
        tweenOpen:Play()
    end
end

ContextActionService:BindAction(ACTION_STATS, function(actionName, inputState, _inputObject)
    if actionName == ACTION_STATS then
        if inputState == Enum.UserInputState.Begin then
            openOrCloseStatsMenu()
        end
    end
end, false, Enum.KeyCode.G)

storageButton.Activated:Connect(function(inputObject, clickCount)
    openOrCloseStatsMenu()
end)