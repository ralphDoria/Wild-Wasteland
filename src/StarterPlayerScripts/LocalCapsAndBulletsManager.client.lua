local ReplicatedStorage = game:GetService("ReplicatedStorage")

local playSound = require(ReplicatedStorage:FindFirstChild("PlaySoundUtil", true))

local rev_statChangeSound = ReplicatedStorage:FindFirstChild("StatChangeSound", true)

local coinCollectSound : Sound = game:GetService("SoundService").CurrencySystem["Coins ka-ching"]

rev_statChangeSound.OnClientEvent:Connect(function(statName : string)
    if statName == "Caps" then
        playSound(coinCollectSound, nil, 0)
    elseif statName == "Bullets" then

    else
        warn("parameter passed does not match any existing stat name")
    end
end)

local statsBillboard : Frame = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("StatsGui").Billboard
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
            print("test")
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