local player = game:GetService("Players").LocalPlayer

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)
local rev_singleSpawn = ReplicatedStorage:FindFirstChild("SingleSpawn", true)

local tweenTime = 2
local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

--gui instance references
local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")  
local updateMisc : BindableEvent = gui:FindFirstChildWhichIsA("BindableEvent", true)
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

local function truncate(num, decimalPlaces : number)
    if num%1 == 0 then return num end
    local decimalPosition = string.find(tostring(num), ".")
    return tonumber(string.sub(tostring(num), 1, decimalPosition + 1 + decimalPlaces))
end

--[[
    Abbreviates numbers, only handles numbers below 1 Trillion
]]
local function numberAbbreviator(num : number)
    local K = 1_000
    local M = 1_000_000
    local B = 1_000_000_000

    local abbreviatorsGreatestToLeast = {
        [1] = {B, "B"},
        [2] = {M, "M"},
        [3] = {K, "K"}
    }

    for _, v in abbreviatorsGreatestToLeast do
        local preTruncate : number = tonumber(string.format("%f", num/v[1]))
        local shortened : number = truncate(preTruncate, 1)
        --print(preTruncate .. " --> " .. shortened)
        local abbreviator : string = v[2]
        if shortened >= 1 then
            if shortened < 10 then
                return tostring(shortened) .. abbreviator
            else
                return tostring(math.round(shortened - 0.5)) .. abbreviator --round down 
            end
        end
    end

    return nil
end

--[[
Puts commas in large numbers, for when hovering to reveal what's behind the abbreviated number
]]
local function comma_value(amount)
    local formatted = amount
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k==0 then
            break
        end
    end

    return formatted
end

function misc.initDisplayAndUpdateEvents()

    local function updateBillboardGui(stat, amountGained : number, newAmount : number)
        local abbreviated = numberAbbreviator(newAmount)
        amountDisplayLabels[stat.name].Text = if abbreviated then abbreviated else newAmount
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
            updateMisc:Fire(stat.name, amountGained)
            updateBillboardGui(stat, amountGained, newAmount)
            lastCachedAmounts[stat.name] = newAmount
        end)

        --when hovering over an ammount label, these events below display the actual ammount (not abbreviated)
        amountDisplayLabels[stat.name].MouseEnter:Connect(function()
            local mouse : Mouse= player:GetMouse()
            local hoverFrame : Frame = gui:FindFirstChild("statsHoevrInfo", true):Clone()
            local label : TextLabel = hoverFrame:FindFirstChildOfClass("TextLabel")
            label.Text = comma_value(player:GetAttribute(stat.name))
            hoverFrame.Visible = true
            hoverFrame.Parent = gui
            local hover = RunService.RenderStepped:Connect(function()
                hoverFrame.Position = UDim2.fromOffset(mouse.X, mouse.Y - hoverFrame.AbsoluteSize.Y + if gui.IgnoreGuiInset then game:GetService("GuiService"):GetGuiInset().Y else 0)
            end)
            amountDisplayLabels[stat.name].MouseLeave:Once(function()
                if hover then
                    hover:Disconnect()
                    hover = nil
                    hoverFrame:Destroy()
                end
            end)
        end)
    end
end

--[[replaces any numbers in the textbox with an empty string]]
local function stripNonNumbers(textBox : TextBox)
	textBox.Text = textBox.Text:gsub("%D","")
end

local blacklistedParts = {}
local function castRay(originPosition : Vector3, targetPosition : Vector3)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.IgnoreWater = true

    local rayMaxDistance : number = 250
    local rayDirection : Vector3 = (targetPosition - originPosition).Unit * rayMaxDistance

    local raycastResult : RaycastResult = workspace:Raycast(originPosition, rayDirection, raycastParams)

    if raycastResult ~= nil and raycastResult.Instance.Parent:FindFirstChild("Humanoid") then
        table.insert(blacklistedParts, raycastResult.Instance.Parent)
        raycastParams.FilterDescendantsInstances = blacklistedParts
        --print("recursion 2")
        return castRay()
    else
        return raycastResult
    end
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
                    local originPosition : Vector3 = (player.character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)).Position
                    local raycastResult = castRay(originPosition, originPosition + Vector3.new(0, -500, 0))
                    if player:GetAttribute(statName) >= numberInput and raycastResult then
                        --fire remote event to change attribute
                        inputBox.Text = "Success"
                        inputBox.TextColor3 = Color3.fromRGB(0, 255, 13)
                        cooldown = 5
                        rev_singleSpawn:FireServer(raycastResult.Position, raycastResult.Normal, statName, numberInput)
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