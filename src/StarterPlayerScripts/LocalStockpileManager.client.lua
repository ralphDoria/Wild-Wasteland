local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local rev_statChangeSound = ReplicatedStorage:FindFirstChild("StatChangeSound", true)

local SoundService = game:GetService("SoundService")
local coinCollectSound : Sound = SoundService.CurrencySystem["Coins ka-ching"]
local ammoCollectSound : Sound = SoundService:FindFirstChild("Ammo pickup", true)

rev_statChangeSound.OnClientEvent:Connect(function(statName : string)
    if statName == "Caps" then
        playSound(coinCollectSound, nil, 0)
    elseif statName == "Ammo" then
        playSound(ammoCollectSound, nil, 0)
    else
        warn("parameter passed does not match any existing stat name")
    end
end)

local StatsGui : ScreenGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("StatsGui")
local statsBillboard : Frame = StatsGui.Billboard
local storageButton : ImageButton = StatsGui:WaitForChild("StorageButton")
--closed box: 18511847325
--open box: 18511845518
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
ContextActionService:BindAction(ACTION_STATS, function(actionName, inputState, _inputObject)
    if actionName == ACTION_STATS then
        if inputState == Enum.UserInputState.Begin then
            if open then
                open = false
                tweenClose:Play()
                tweenClose.Completed:Wait()
                if open == false then
                    statsBillboard.Visible = false 
                end
            else
                statsBillboard.Visible = true
                open = true
                tweenOpen:Play()
            end
        end
    end
end, true, Enum.KeyCode.M)