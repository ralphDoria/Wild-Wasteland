local player = game:GetService("Players").LocalPlayer

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)

local tweenTime = 2
local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

--gui instance references
local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")  
local miscFrame : Frame = gui:FindFirstChild("misc", true)
local amountDisplayLabels = {
    [playerStatsInfo.ATTRIBUTE_CAPS.name] = miscFrame.Caps.Amount,
    [playerStatsInfo.ATTRIBUTE_LIGHT_BULLETS.name] = miscFrame.LightBullets.Amount,
    [playerStatsInfo.ATTRIBUTE_MEDIUM_BULLETS.name] = miscFrame.MediumBullets.Amount,
    [playerStatsInfo.ATTRIBUTE_HEAVY_BULLETS.name] = miscFrame.HeavyBullets.Amount,
    [playerStatsInfo.ATTRIBUTE_SHELLS.name] = miscFrame.Shells.Amount,
    [playerStatsInfo.ATTRIBUTE_ENERGY_AMMO.name] = miscFrame.EnergyAmmo.Amount,
}

local misc = {}

function misc.init()
    misc.initDisplayAndUpdateEvents()
    misc.initButtons()
end

function misc.initDisplayAndUpdateEvents()
    --[[
        TODO: Make a "item added to inventory" indicator on the middle left of the player's screen that stacks labels & quickly fades them out
        if there are multiple. Have it react to any item added to inventory, not just caps & ammo.
    ]]
    --local gainedResourceIndicator : CanvasGroup = gui.StorageButton:FindFirstChild("Gain", true)

    --functions for updating gui
    --[[
    local function gainedResourceEffect(stat, amountGained : number)
        local x : Frame = gainedResourceIndicator:Clone()
        x.Visible = true
        x.Icon.Image = stat.icon
        x.Amount.Text = "+" .. tostring(amountGained)
        x.Parent = gainedResourceIndicator.Parent
        TweenService:Create(x, ti, {GroupTransparency = 1}):Play()
        Debris:AddItem(x, tweenTime)
    end
    ]]

    local function updateBillboardGui(stat, amountGained : number, newAmount : number)
        amountDisplayLabels[stat.name].Text = newAmount
        --[[
        if amountGained > 0 then
            gainedResourceEffect(stat, amountGained)
        end
        ]]
    end

    while not player:GetAttribute("StatsLoaded") do
        task.wait()
        --print("loading stats")
    end
    for _, stat in playerStatsInfo.getAll() do
        updateBillboardGui(stat, 0, player:GetAttribute(stat.name))
    end

    --detecting changes to attributes & updating gui as needed
    local lastCachedAmounts = {
        [playerStatsInfo.ATTRIBUTE_CAPS.name] = player:GetAttribute(playerStatsInfo.ATTRIBUTE_CAPS.name),
        [playerStatsInfo.ATTRIBUTE_LIGHT_BULLETS.name] = player:GetAttribute(playerStatsInfo.ATTRIBUTE_LIGHT_BULLETS.name), 
        [playerStatsInfo.ATTRIBUTE_MEDIUM_BULLETS.name] = player:GetAttribute(playerStatsInfo.ATTRIBUTE_MEDIUM_BULLETS.name), 
        [playerStatsInfo.ATTRIBUTE_HEAVY_BULLETS.name] = player:GetAttribute(playerStatsInfo.ATTRIBUTE_HEAVY_BULLETS.name),
        [playerStatsInfo.ATTRIBUTE_SHELLS.name] = player:GetAttribute(playerStatsInfo.ATTRIBUTE_SHELLS.name), 
        [playerStatsInfo.ATTRIBUTE_ENERGY_AMMO.name] = player:GetAttribute(playerStatsInfo.ATTRIBUTE_ENERGY_AMMO.name)
    }

    for _, stat in playerStatsInfo.getAll() do
        player:GetAttributeChangedSignal(stat.name):Connect(function()
            local newAmount : number = player:GetAttribute(stat.name)
            local amountGained : number = player:GetAttribute(stat.name) - lastCachedAmounts[stat.name]
            updateBillboardGui(stat, amountGained, newAmount)
            lastCachedAmounts[stat.name] = newAmount
        end)
    end
end

--[[replaces any numbers in the textbox with an empty string]]
local function stripNonNumbers(textBox : TextBox)
	textBox.Text = textBox.Text:gsub("%D","")
end

function misc.initButtons()
    for _, v in amountDisplayLabels do
        local statName = v.Parent.Name
        local button : TextButton = v.Parent:FindFirstChildOfClass("TextButton")
        local inputBox : TextBox = v.Parent:FindFirstChildOfClass("TextBox")
        inputBox.Size = UDim2.fromScale(0,1)
        inputBox.TextTransparency = 1
        local restrictToNumbersOnly = nil --allows only numbers in the textbox when connected to

        local opened = false
        local canClick = true
        button.MouseButton1Click:Connect(function()
            if canClick == false then return end
            if not opened then
                opened = true
                inputBox.TextEditable = true
                inputBox.ClearTextOnFocus = true
                inputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
                local boxExpanding = TweenService:Create(inputBox, TweenInfo.new(0.5), {Size = UDim2.fromScale(1,1)})
                button.Text = "X"
                inputBox.Text = "Enter Amount Here"
                if restrictToNumbersOnly == nil then
                    restrictToNumbersOnly = inputBox:GetPropertyChangedSignal("Text"):Connect(function()
                        stripNonNumbers(inputBox)
                        local onlyNumbers : boolean = tonumber(inputBox.Text) ~= nil
                        if onlyNumbers and tonumber(inputBox.Text) ~= 0 then
                            button.Text = "✓"
                        else
                            button.Text = "X"
                        end
                    end)
                end
                TweenService:Create(inputBox, TweenInfo.new(0.5), {TextTransparency = 0}):Play()
                boxExpanding:Play()
            else
                if restrictToNumbersOnly ~= nil then
                    restrictToNumbersOnly:Disconnect()
                    restrictToNumbersOnly = nil
                end
                inputBox.TextEditable = false
                inputBox.ClearTextOnFocus = false

                local cooldown : number
                local closeDelay : number
                local numberInput = tonumber(inputBox.Text)
                if numberInput == nil or numberInput == 0 then
                    cooldown = 0
                    closeDelay = 0
                else
                    closeDelay = 0.5
                    if player:GetAttribute(statName) >= numberInput then
                        --fire remote event to change attribute
                        inputBox.Text = "Success"
                        inputBox.TextColor3 = Color3.fromRGB(0, 255, 13)
                        cooldown = 5
                    else
                        inputBox.Text = "Error"
                        inputBox.TextColor3 = Color3.fromRGB(255, 0, 0)
                        cooldown = 0
                    end
                end
                local boxClosing = TweenService:Create(inputBox, TweenInfo.new(0.5), {Size = UDim2.fromScale(0,1)})
                task.spawn(function()
                    task.wait(closeDelay)
                    boxClosing:Play()
                    TweenService:Create(inputBox, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
                end)
                canClick = false
                opened = false
                button.TextTransparency = 0.5
                if cooldown ~= 0 then
                    for i = cooldown, 1, -1 do
                        button.Text = i
                        task.wait(1)
                    end
                end
                button.TextTransparency = 0.5
                button.Text = "↓"
                while boxClosing.PlaybackState ~= Enum.PlaybackState.Completed do
                    --print("Waiting for tween to complete")
                    task.wait()
                end
                canClick = true
                button.TextTransparency = 0
            end
        end)
    end
end

return misc