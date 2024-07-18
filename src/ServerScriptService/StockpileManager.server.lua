local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)

local tweenTime = 2
local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    --gui instance references
    local StatsGui : ScreenGui = player.PlayerGui:WaitForChild("StatsGui")  
    local billboardAmmo : Frame = StatsGui.Billboard.Ammo
    local billboardAmountLabels = {
        [playerStatsInfo.ATTRIBUTE_CAPS.name] = StatsGui.Billboard.Caps.BloxyCola.Amount,
        [playerStatsInfo.ATTRIBUTE_LIGHT_BULLETS.name] = billboardAmmo.LightBullets.Amount,
        [playerStatsInfo.ATTRIBUTE_MEDIUM_BULLETS.name] = billboardAmmo.MediumBullets.Amount,
        [playerStatsInfo.ATTRIBUTE_HEAVY_BULLETS.name] = billboardAmmo.HeavyBullets.Amount,
        [playerStatsInfo.ATTRIBUTE_SHELLS.name] = billboardAmmo.Shells.Amount,
        [playerStatsInfo.ATTRIBUTE_ENERGY_AMMO.name] = billboardAmmo.EnergyAmmo.Amount,
    }
    local gainedResourceIndicator : CanvasGroup = StatsGui.StorageButton:FindFirstChild("Gain", true)

    --functions for updating gui
    local function gainedResourceEffect(stat, amountGained : number)
        local x : Frame = gainedResourceIndicator:Clone()
        x.Visible = true
        x.Icon.Image = stat.icon
        x.Amount.Text = "+" .. tostring(amountGained)
        x.Parent = gainedResourceIndicator.Parent
        TweenService:Create(x, ti, {GroupTransparency = 1}):Play()
        Debris:AddItem(x, tweenTime)
    end

    local function updateBillboardGui(stat, amountGained : number, newAmount : number)
        billboardAmountLabels[stat.name].Text = newAmount
        if amountGained > 0 then
            gainedResourceEffect(stat, amountGained)
        end
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
end)



----------------------------------------------------------------
local CollectionService = game:GetService("CollectionService")

local TAG_CURRENCY = "DroppedCurrency"
local TAG_AMMO = "DroppedAmmo"

local currencyProxProm : ProximityPrompt = workspace:FindFirstChild("BottleCaps", true).ProximityPrompt
local ammoProxProm : ProximityPrompt = workspace:FindFirstChild("AmmoCans", true).ProximityPrompt

local function handleTaggedInstance(tagName, taggedInstance)
    local clonedProxProm
    if tagName == TAG_CURRENCY then
        clonedProxProm = currencyProxProm:Clone()
    elseif tagName == TAG_AMMO then
        clonedProxProm = ammoProxProm:Clone()
    else
        warn("Invalid tag name")
        return
    end
    clonedProxProm.Parent = taggedInstance.PrimaryPart
    clonedProxProm.Triggered:Connect(function(player)
        currencyProxProm.Enabled = false
        taggedInstance:Destroy()
        if tagName == TAG_CURRENCY then
            local pileValue = math.random(10, 20)
            player:SetAttribute(playerStatsInfo.ATTRIBUTE_CAPS.name, player:GetAttribute(playerStatsInfo.ATTRIBUTE_CAPS.name) + pileValue)
            rev_statChangeSound:FireClient(player, TAG_CURRENCY)
        elseif tagName == TAG_AMMO then
            local numberOfAmmoTypesToGive = math.random(1, #playerStatsInfo.getAmmo())
            local clonedTable = table.clone(playerStatsInfo.getAmmo())
            for count = 1, numberOfAmmoTypesToGive, 1 do
                local randomAmmoType = clonedTable[math.random(1, #clonedTable)].name
                local ammoAmount = math.random(10, 30)
                player:SetAttribute(randomAmmoType, player:GetAttribute(randomAmmoType) + ammoAmount)
            end
            rev_statChangeSound:FireClient(player, TAG_AMMO)
        end
    end)
end
for _, taggedInstance in CollectionService:GetTagged(TAG_CURRENCY) do
    handleTaggedInstance(TAG_CURRENCY, taggedInstance)
end
CollectionService:GetInstanceAddedSignal(TAG_CURRENCY):Connect(function(taggedInstance)
    handleTaggedInstance(TAG_CURRENCY, taggedInstance)
end)

for _, taggedInstance in CollectionService:GetTagged(TAG_AMMO) do
    handleTaggedInstance(TAG_AMMO, taggedInstance)
end
CollectionService:GetInstanceAddedSignal(TAG_AMMO):Connect(function(taggedInstance)
    handleTaggedInstance(TAG_AMMO, taggedInstance)
end)

