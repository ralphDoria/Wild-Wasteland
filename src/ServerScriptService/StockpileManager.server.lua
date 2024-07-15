local ATTRIBUTE_CAPS = "Caps"
local ATTRIBUTE_LIGHT_BULLETS = "LightBullets"
local ATTRIBUTE_MEDIUM_BULLETS = "MediumBullets"
local ATTRIBUTE_HEAVY_BULLETS = "HeavyBullets"
local ATTRIBUTE_SHELLS = "Shells"
local ATTRIBUTE_ENERGY_AMMO = "EnergyAmmo"
local ammoAttributes = {ATTRIBUTE_LIGHT_BULLETS, ATTRIBUTE_MEDIUM_BULLETS, ATTRIBUTE_HEAVY_BULLETS, ATTRIBUTE_SHELLS, ATTRIBUTE_ENERGY_AMMO}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DataStoreService = game:GetService("DataStoreService")
local DATA_CAPS = "PlayerCaps"
local PlayerCaps = DataStoreService:GetDataStore(DATA_CAPS)

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)

local tweenTime = 1
local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    local StatsGui : ScreenGui = player.PlayerGui:WaitForChild("StatsGui")  

    local billboardCapsAmount : TextLabel = StatsGui.Billboard.Caps.BloxyCola.Amount
    --local billboardAmmo : TextLabel = StatsGui.Billboard.Ammo

    local hudCapsAmount : TextLabel = StatsGui.hudCapsDisplay:FindFirstChild("Amount", true)
    local hudCapsGain :  TextLabel = StatsGui.hudCapsDisplay:FindFirstChild("Gain", true)

    local function capsGainEffect(capsGained : number)
        local x : TextLabel = hudCapsGain:Clone()
        x.Visible = true
        x.Text = "+" .. tostring(capsGained)
        x.Parent = hudCapsGain.Parent
        TweenService:Create(x, ti, {Position = UDim2.new(1, 0, -1, 0)}):Play()
        TweenService:Create(x, ti, {TextTransparency = 1}):Play()
        Debris:AddItem(x, tweenTime)
    end

    local function updateCapGui(capsGained : number, newCapAmount : number)
        billboardCapsAmount.Text = newCapAmount
        capsGainEffect(capsGained)
        hudCapsAmount.Text = tostring(newCapAmount)
    end

    --[[
    local function setBulletsAmount(bullets : number)
        billboardBulletsAmount.Text = tostring(bullets)
    end
    ]]

    local wasSuccess, currentCaps = pcall(function()
        return PlayerCaps:GetAsync(player.UserId)
    end)
    player:SetAttribute(ATTRIBUTE_CAPS, if currentCaps then currentCaps else 0)
    updateCapGui(0, currentCaps)

    local oldCapAmount : number = player:GetAttribute(ATTRIBUTE_CAPS)

    player:GetAttributeChangedSignal(ATTRIBUTE_CAPS):Connect(function()
        local newCapAmount = player:GetAttribute(ATTRIBUTE_CAPS)
        local capGain = player:GetAttribute(ATTRIBUTE_CAPS) - oldCapAmount
        --print(tostring(oldCapAmount) .. " + " .. tostring(capGain) .. " = " .. tostring(newCapAmount))
        updateCapGui(capGain, newCapAmount)
        oldCapAmount = newCapAmount
        rev_statChangeSound:FireClient(player, ATTRIBUTE_CAPS)
    end)

    for _, attributeName in ammoAttributes do
        player:SetAttribute(attributeName, 0) --use a pcall later
        local oldBulletAmount : number = player:GetAttribute(attributeName)
        player:GetAttributeChangedSignal(attributeName):Connect(function()
            local newBulletAmount
            local bulletGain
            rev_statChangeSound:FireClient(player, attributeName)
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
    print(taggedInstance.Name)
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
            player:SetAttribute(ATTRIBUTE_CAPS, player:GetAttribute(ATTRIBUTE_CAPS) + pileValue)
        elseif tagName == TAG_AMMO then
            local numberOfAmmoTypesToGive = math.random(1, #ammoAttributes)
            local clonedTable = table.clone(ammoAttributes)
            for count = 1, numberOfAmmoTypesToGive, 1 do
                local randomAmmoType = clonedTable[math.random(1, #clonedTable)]
                local ammoAmount = math.random(10, 30)
                player:SetAttribute(randomAmmoType, player:GetAttribute(randomAmmoType) + ammoAmount)
            end
            print("Ammo collection not implemented yet, but this here is a placeholder.")
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

