local player = game:GetService("Players").LocalPlayer
local gui : ScreenGui = player.PlayerGui:WaitForChild("LootingGui")
local mainFrame : Frame = gui.main
local exit : TextButton = gui.Exit
local misc = gui.main.misc
local metaItems = {
    caps = misc.Caps,
    lightBullets = misc.LightBullets,
    mediumBullets = misc.MediumBullets,
    heavyBullets = misc.HeavyBullets,
    shells = misc.Shells,
    energyAmmo = misc.EnergyAmmo
}
local inventoryAndHotbar = player.PlayerGui:WaitForChild("InventoryAndHotbar")
local TweenService = game:GetService("TweenService")

mainFrame.Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0)
mainFrame.Visible = false
exit.Visible = false
gui.Enabled = true

local openTween : Tween = TweenService:Create(mainFrame, TweenInfo.new(0.4), {Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0.5)})
local closeTween : Tween = TweenService:Create(mainFrame, TweenInfo.new(0.1), {Size = UDim2.fromScale(mainFrame.Size.X.Scale, 0)})

local LootingGuiController = {}

local selectedMetaItem = nil

local function initMisc()

    local currentlyHoveringOn = nil
    for _, v in metaItems do
        v.MouseEnter:Connect(function()
            TweenService:Create(v, TweenInfo.new(0.5), {BackgroundTransparency = 0.2}):Play()
        end)
        v.MouseLeave:Connect(function()
            TweenService:Create(v, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
        end)
        v.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                v.Interactable = false
                TweenService:Create(v, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
                selectedMetaItem = v
                for _, v2 in misc:GetChildren() do
                    if v2:IsA("GuiObject") then
                        v2.Visible = false
                    end
                end
                v.Visible = true
                misc.transferControls.Visible = true
            end
        end)
    end

end

misc.transferControls.cancel.MouseButton1Click:Connect(function()
    for _, v in misc:GetChildren() do
        if v:IsA("GuiObject") then
            v.Visible = true
        end
    end
    misc.transferControls.Visible = false
    selectedMetaItem.Interactable = true
    selectedMetaItem = nil
end)

function LootingGuiController.init()
    initMisc()
end

function LootingGuiController.showGui()
    mainFrame.Visible = true
    inventoryAndHotbar.Enabled = false
    exit.Visible = true
    openTween:Play()
    return openTween
end

function LootingGuiController.closeGui()
    closeTween.Completed:Once(function()
        if not (openTween.PlaybackState == 2 or closeTween.PlaybackState == 2) then
            mainFrame.Visible = false
            exit.Visible = false
            inventoryAndHotbar.Enabled = true
        end
    end)
    closeTween:Play()
    return closeTween
end

return LootingGuiController