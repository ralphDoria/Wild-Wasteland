local player = game:GetService("Players").LocalPlayer

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)

local tweenTime = 2
local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local misc = {}

function misc.initDisplayAndEvents()
    --gui instance references
    local gui : ScreenGui = player.PlayerGui:WaitForChild("InventoryAndHotbar")  
    local misc : Frame = gui:FindFirstChild("misc", true)
    local amountDisplayLabels = {
        [playerStatsInfo.ATTRIBUTE_CAPS.name] = misc.BloxyCola.Amount,
        [playerStatsInfo.ATTRIBUTE_LIGHT_BULLETS.name] = misc.LightBullets.Amount,
        [playerStatsInfo.ATTRIBUTE_MEDIUM_BULLETS.name] = misc.MediumBullets.Amount,
        [playerStatsInfo.ATTRIBUTE_HEAVY_BULLETS.name] = misc.HeavyBullets.Amount,
        [playerStatsInfo.ATTRIBUTE_SHELLS.name] = misc.Shells.Amount,
        [playerStatsInfo.ATTRIBUTE_ENERGY_AMMO.name] = misc.EnergyAmmo.Amount,
    }
    
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

return misc