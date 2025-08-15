local TweenService = game:GetService("TweenService")
local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):: PlayerGui
local TransitionBlackScreen = playerGui:WaitForChild("TransitionBlackScreen"):: ScreenGui
local Frame = TransitionBlackScreen.Frame:: Frame

local TransitionBlackScreenManager = {}

function TransitionBlackScreenManager.fadeIn(tweenTime: number): Tween
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Frame, tweenInfo, {BackgroundTransparency = 0}):Play()
    return tween
end

function TransitionBlackScreenManager.fadeOut(tweenTime: number): Tween
    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(Frame, tweenInfo, {BackgroundTransparency = 1}):Play()
    return tween
end

function TransitionBlackScreenManager.getTransparency(): number
    return Frame.Transparency
end

TransitionBlackScreenManager.fadeOut(0)
TransitionBlackScreen.Enabled = true

return TransitionBlackScreenManager