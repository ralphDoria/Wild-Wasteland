local player = game:GetService("Players").LocalPlayer
local gui = player.PlayerGui:WaitForChild("LootingGui")
local inventoryAndHotbar = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local rev_toggleOpen = game:GetService("ReplicatedStorage").LootingSystem:FindFirstChild("toggleOpen", true)
local TweenService = game:GetService("TweenService")

local lootContainer = workspace:FindFirstChild("lootContainer", true)
local pp : ProximityPrompt = lootContainer:WaitForChild("filler"):WaitForChild("ProximityPrompt")

local mainFrame = gui.main
local exit : TextButton = gui.Exit
mainFrame.Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0)
mainFrame.Visible = false
exit.Visible = false
gui.Enabled = true

local openTween : Tween = TweenService:Create(mainFrame, TweenInfo.new(0.4), {Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0.5)})
local closeTween : Tween = TweenService:Create(mainFrame, TweenInfo.new(0.1), {Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0)})

pp.Triggered:Connect(function()
    pp.Enabled = false
    rev_toggleOpen:FireServer(true)
    openTween.Completed:Once(function()
        if not (openTween.PlaybackState == 2 or closeTween.PlaybackState == 2) then
            
        end
    end)
    mainFrame.Visible = true
    inventoryAndHotbar.Enabled = false
    exit.Visible = true
    openTween:Play()

    exit.MouseButton1Click:Once(function()
        closeTween.Completed:Once(function()
            if not (openTween.PlaybackState == 2 or closeTween.PlaybackState == 2) then
                mainFrame.Visible = false
                exit.Visible = false
                pp.Enabled = true
                inventoryAndHotbar.Enabled = true
            end
        end)
        closeTween:Play()
        rev_toggleOpen:FireServer(false)
    end)
end)