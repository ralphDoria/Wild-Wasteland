-- This script runs in StarterPlayerScripts and the ScreenGui does not reset on spawn
-- !strict
local TweenService = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = char:WaitForChild("Humanoid")
local playerGui = player.PlayerGui
local DeathScreen: ScreenGui = playerGui:WaitForChild("DeathScreen")
local _frame: Frame = DeathScreen:WaitForChild("Frame"):: Frame
local _canvasGroup: CanvasGroup = _frame:WaitForChild("CanvasGroup"):: CanvasGroup
local youDiedTextlabel: TextLabel

local respawn_button: TextButton = _canvasGroup:WaitForChild("Respawn"):: TextButton
local respawn_textGradient: UIGradient = respawn_button:WaitForChild("textGradient"):: UIGradient
local respawn_strokeGradient: UIGradient = respawn_button:WaitForChild("UIStroke"):WaitForChild("strokeGradient"):: UIGradient

local menu_button: TextButton = _canvasGroup:WaitForChild("Menu"):: TextButton
local menu_textGradient: UIGradient = menu_button:WaitForChild("textGradient"):: UIGradient
local menu_strokeGradient: UIGradient = menu_button:WaitForChild("UIStroke"):WaitForChild("strokeGradient"):: UIGradient

--Tweens
local hoverTweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, math.huge, false)
respawn_strokeGradient.Rotation = -180
menu_strokeGradient.Rotation = -180
local respawn_hoverTween: Tween = TweenService:Create(respawn_strokeGradient, hoverTweenInfo, {Rotation = 180})
local menu_hoverTween: Tween = TweenService:Create(menu_strokeGradient, hoverTweenInfo, {Rotation = 180})

local startOffset = Vector2.new(0, 1)
respawn_textGradient.Offset = startOffset
menu_textGradient.Offset = startOffset
local endOffset = Vector2.new(0, 0)
local clickTweenInfo = TweenInfo.new(0.5)
local respawn_clickTween: Tween = TweenService:Create(respawn_textGradient, clickTweenInfo, {Offset = endOffset})
local menu_clickTween: Tween = TweenService:Create(menu_textGradient, clickTweenInfo, {Offset = endOffset})

local SoundFolder: Folder = DeathScreen:WaitForChild("SoundFolder"):: Folder
local sound: Sound = SoundFolder:FindFirstChildOfClass("Sound"):: Sound

local RS = game:GetService("ReplicatedStorage")
local CharacterStatsGuiSystem_Storage = RS:FindFirstChild("CharacterStatsGuiSystem_Storage", true)
local remotes: {[string]: RemoteEvent} = {
    RespawnPlayerCharacter = CharacterStatsGuiSystem_Storage:FindFirstChild("RespawnPlayerCharacter", true)
}

local DeathScreenManager = {}

DeathScreen.Enabled = false
_frame.BackgroundTransparency = 1
_frame.Visible = true

local function init()
    humanoid.Died:Once(function()  
        respawn_button.MouseEnter:Connect(function()  
            respawn_strokeGradient.Enabled = true
            respawn_hoverTween:Play()
        end) 
        menu_button.MouseEnter:Connect(function()  
            menu_strokeGradient.Enabled = true
            menu_hoverTween:Play()
        end) 
        respawn_button.MouseLeave:Connect(function()  
            respawn_strokeGradient.Enabled = false
            respawn_hoverTween:Cancel()
        end) 
        menu_button.MouseLeave:Connect(function()  
            menu_strokeGradient.Enabled = false
            menu_hoverTween:Cancel()
        end) 

        respawn_button.MouseButton1Click:Connect(function()  
            respawn_clickTween:Play()
            remotes.RespawnPlayerCharacter:FireServer()
            player.CharacterAdded:Wait()
            local fadeOutTime = 1
            local tweenInfo = TweenInfo.new(fadeOutTime)
            TweenService:Create(_frame, tweenInfo, {BackgroundTransparency = 1}):Play()
            TweenService:Create(_canvasGroup, tweenInfo, {GroupTransparency = 1}):Play()
            task.wait(fadeOutTime)
        end) 
        menu_button.MouseButton1Click:Connect(function()  
            menu_clickTween:Play()
        end) 

        -- tween in death screen
        DeathScreen.Enabled = true
        _canvasGroup.GroupTransparency = 1
        _canvasGroup.Visible = true
        local fadeInTime = 5
        local tweenInfo = TweenInfo.new(fadeInTime)
        TweenService:Create(_frame, tweenInfo, {BackgroundTransparency = 0}):Play()
        task.wait(fadeInTime - 2)

        TweenService:Create(_canvasGroup, tweenInfo, {GroupTransparency = 0}):Play()
        sound:Play()
    end)
end

init()