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

local function toggleAllMiscVisibility(toggle : boolean)
    for _, v in misc:GetChildren() do
        if v:IsA("GuiObject") then
            v.Visible = toggle
        end
    end
end

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
                toggleAllMiscVisibility(false)
                v.Visible = true
                misc.transferControls.Visible = true
            end
        end)
    end

end

local function tweenWrapper(object, time : number, property)
    return TweenService:Create(object, TweenInfo.new(time), property)
end

local function initTransferControls()
    local left = misc.transferControls:FindFirstChild("left", true)
    local right = misc.transferControls:FindFirstChild("right", true)
    local textBox : TextBox = misc.transferControls:FindFirstChild("TextBox", true)
    local enterAll : TextButton = misc.transferControls:FindFirstChild("enterAll", true)
    local cancel : TextButton = misc.transferControls.cancel
    local confirm : TextButton = misc.transferControls.confirm
    -- 0: neither, 1: left, 2: right
    local activated = 0
    local previouslyActivated = nil

    local function changeActivated(value : number)
        previouslyActivated = activated
        activated = value
    end

    tweenWrapper(textBox, 0, {Size = UDim2.fromScale(0,0)}):Play()
    tweenWrapper(textBox, 0, {TextTransparency = 1}):Play()

    local function toggleAmountControls(toggle : boolean)
        if toggle then
            tweenWrapper(textBox, 0.2, {Size = UDim2.fromScale(1, 0.333)}):Play()
            tweenWrapper(enterAll, 0.2, {Size = UDim2.fromScale(1, 0.333)}):Play()
            tweenWrapper(textBox, 0.1, {TextTransparency = 0}):Play()
            tweenWrapper(enterAll, 0.1, {TextTransparency = 0}):Play()
        else
            tweenWrapper(textBox, 0.2, {Size = UDim2.fromScale(1,0)}):Play()
            tweenWrapper(enterAll, 0.2, {Size = UDim2.fromScale(1, 0)}):Play()
            tweenWrapper(textBox, 0.1, {TextTransparency = 1}):Play()
            tweenWrapper(enterAll, 0.1, {TextTransparency = 1}):Play()
        end
    end

    local function toggleConfirmVisibility(toggle : boolean)
        if toggle then
            tweenWrapper(confirm, 0.2, {Size = UDim2.fromScale(confirm.Size.X.Scale, 0.2)}):Play()
            tweenWrapper(confirm, 0.1, {TextTransparency = 0}):Play()
        else
            tweenWrapper(confirm, 0.2, {Size = UDim2.fromScale(confirm.Size.X.Scale, 0)}):Play()
            tweenWrapper(confirm, 0.1, {TextTransparency = 1}):Play()
        end
    end

    local function initialState()
        toggleAmountControls(false)
        tweenWrapper(confirm, 0, {Size = UDim2.fromScale(confirm.Size.X.Scale, 0)}):Play()
        tweenWrapper(confirm, 0, {TextTransparency = 1}):Play()
        misc.transferControls.Visible = false
    end
    initialState()

    local function foo() --idk what to call this function yet
        if (previouslyActivated == 1 or previouslyActivated == 2) and activated ~= 0 then
            toggleAmountControls(false)
            task.wait(0.2)
            toggleAmountControls(true)
        elseif activated ~= 0 then
            toggleAmountControls(true)
            task.wait(0.2)
        else
            toggleAmountControls(false)
        end
    end

    left.Activated:Connect(function()
        if activated ~= 1 then --remember, 1 means left
            changeActivated(1)
            left:FindFirstChildWhichIsA("UIStroke", true).Thickness = 5
            right:FindFirstChildWhichIsA("UIStroke", true).Thickness = 1
        else
            changeActivated(0)
            left:FindFirstChildWhichIsA("UIStroke", true).Thickness = 1
        end
        foo()
    end)
    right.Activated:Connect(function()
        if activated ~= 2 then --remember, 2 means right
            changeActivated(2)
            right:FindFirstChildWhichIsA("UIStroke", true).Thickness = 5
            left:FindFirstChildWhichIsA("UIStroke", true).Thickness = 1
        else
            changeActivated(0)
            right:FindFirstChildWhichIsA("UIStroke", true).Thickness = 1
        end
        foo()
    end)
    cancel.MouseButton1Click:Connect(function()
        toggleAllMiscVisibility(true)
        misc.transferControls.Visible = false
        selectedMetaItem.Interactable = true
        selectedMetaItem = nil
    end)
    confirm.MouseButton1Click:Connect(function()
    end)
end

function LootingGuiController.init()
    initMisc()
    initTransferControls()
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