local player = game:GetService("Players").LocalPlayer
local gui: ScreenGui = player.PlayerGui:WaitForChild("DiegeticErrorMessaging")
local frame = gui:WaitForChild("Frame"):: Frame
local template = frame:WaitForChild("msg"):: TextLabel
template.Parent = nil
local TweenService = game:GetService("TweenService")

DiegeticErrorMessagingManager = {}
local messageNumber = 0

local minTime = 1.5
local maxTime = 4
local function calculateDisplayTime(message: string, minTime, maxTime): number
    local wordCount = #message:split(" ")
    return math.clamp(1.5 + wordCount * 0.25, minTime, maxTime)
end

gui.Enabled = true

function createMsgClone(message: string): TextLabel
    local clone = template:Clone()
    clone.Visible = true
    messageNumber += 1
    clone.LayoutOrder = messageNumber
    clone.Text = message
    return clone
end

function DiegeticErrorMessagingManager.AddMessage(message: string)
    -- print("Creating and adding message")
    local clone = createMsgClone(message)
    clone.Parent = frame
    local fadeOutTween = TweenService:Create(
        clone, 
        TweenInfo.new(calculateDisplayTime(message, minTime, maxTime), Enum.EasingStyle.Exponential, Enum.EasingDirection.In), 
        {TextTransparency = 1}
    )
    fadeOutTween:Play()
    fadeOutTween.Completed:Once(function(a0: Enum.PlaybackState)  
        clone:Destroy()
    end)
end

return DiegeticErrorMessagingManager