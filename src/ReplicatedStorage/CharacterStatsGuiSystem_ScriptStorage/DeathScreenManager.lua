--This script will run in StarterPlayerScripts
-- !strict
local TweenService = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = char:WaitForChild("Humanoid")
local playerGui = player.PlayerGui
local DeathScreen: ScreenGui = playerGui:WaitForChild("DeathScreen")
local _frame: Frame = DeathScreen:WaitForChild("Frame"):: Frame
local youDiedTextlabel: TextLabel

local respawn_button: TextButton = _frame:WaitForChild("Respawn"):: TextButton
local respawn_textGradient: UIGradient = respawn_button:WaitForChild("textGradient"):: UIGradient
local respawn_strokeGradient: UIGradient = respawn_textGradient:WaitForChild("UIStroke"):WaitForChild("strokeGradient"):: UIGradient

local menu_button: TextButton = _frame:WaitForChild("Menu"):: TextButton
local menu_textGradient: UIGradient = menu_button:WaitForChild("textGradient"):: UIGradient
local menu_strokeGradient: UIGradient = menu_textGradient:WaitForChild("UIStroke"):WaitForChild("strokeGradient"):: UIGradient

--Tweens
local hoverTweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge)
respawn_strokeGradient.Rotation = -180
menu_strokeGradient.Rotation = -180
local respawn_hoverTween: Tween = TweenService:Create(respawn_strokeGradient, hoverTweenInfo, {Rotation = 180})
local menu_hoverTween: Tween = TweenService:Create(menu_strokeGradient, hoverTweenInfo, {Rotation = 180})

local clickTweenInfo = TweenInfo.new(0.5)
local start_colorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.999, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
respawn_textGradient.Color = start_colorSequence
menu_textGradient.Color = start_colorSequence

local end_colorSequence = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.001, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0))
})
local respawn_clickTween: Tween = TweenService.new(respawn_textGradient, clickTweenInfo, {Color = start_colorSequence})
local menu_clickTween: Tween = TweenService.new(respawn_textGradient, clickTweenInfo, {Color = end_colorSequence})

local sound: Sound = DeathScreen:WaitForChild("If I Knew"):: Sound

local DeathScreenManager = {}

function DeathScreenManager.init()
    humanoid.Died:Once(function()  
        respawn_button.MouseEnter:Connect(function()  
            respawn_hoverTween:Play()
        end) 
        menu_button.MouseEnter:Connect(function()  
            menu_hoverTween:Play()
        end) 
        respawn_button.MouseLeave:Connect(function()  
            respawn_hoverTween:Cancel()
        end) 
        menu_button.MouseLeave:Connect(function()  
            menu_hoverTween:Cancel()
        end) 

        respawn_button.MouseButton1Click:Connect(function()  
            respawn_clickTween:Play()
        end) 
        menu_button.MouseButton1Click:Connect(function()  
            menu_clickTween:Play()
        end) 
    end)
end

return DeathScreenManager