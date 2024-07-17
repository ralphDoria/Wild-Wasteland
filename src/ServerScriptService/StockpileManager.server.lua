local ATTRIBUTE_CAPS = "Caps"
local ATTRIBUTE_LIGHT_BULLETS = "LightBullets"
local ATTRIBUTE_MEDIUM_BULLETS = "MediumBullets"
local ATTRIBUTE_HEAVY_BULLETS = "HeavyBullets"
local ATTRIBUTE_SHELLS = "Shells"
local ATTRIBUTE_ENERGY_AMMO = "EnergyAmmo"
local ammoAttributes = {ATTRIBUTE_LIGHT_BULLETS, ATTRIBUTE_MEDIUM_BULLETS, ATTRIBUTE_HEAVY_BULLETS, ATTRIBUTE_SHELLS, ATTRIBUTE_ENERGY_AMMO}
local attributeIconMap = {
    [ATTRIBUTE_CAPS] = "rbxassetid://18384549702", 
    [ATTRIBUTE_LIGHT_BULLETS] = "http://www.roblox.com/asset/?id=18506827412", 
    [ATTRIBUTE_MEDIUM_BULLETS] = "http://www.roblox.com/asset/?id=18506830649",
    [ATTRIBUTE_HEAVY_BULLETS] = "http://www.roblox.com/asset/?id=18506834591",
    [ATTRIBUTE_SHELLS] = "http://www.roblox.com/asset/?id=18506837756", 
    [ATTRIBUTE_ENERGY_AMMO] = "http://www.roblox.com/asset/?id=18507047762"
}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DataStoreService = game:GetService("DataStoreService")
local DATA_CAPS = "PlayerCaps"
local DATA_LIGHT_BULLETS = "PlayerLightBullets"
local DATA_MEDIUM_BULLETS = "PlayerMediumBullets"
local DATA_HEAVY_BULLETS = "PlayerHeavyBullets"
local DATA_SHELLS = "PlayerShells"
local DATA_ENERGY_AMMO = "PlayerEnergyAmmo"
local PlayerCaps = DataStoreService:GetDataStore(DATA_CAPS)
local DataStores = {
    [ATTRIBUTE_LIGHT_BULLETS] = DataStoreService:GetDataStore(DATA_LIGHT_BULLETS), 
    [ATTRIBUTE_MEDIUM_BULLETS] = DataStoreService:GetDataStore(DATA_MEDIUM_BULLETS), 
    [ATTRIBUTE_HEAVY_BULLETS] = DataStoreService:GetDataStore(DATA_HEAVY_BULLETS),
    [ATTRIBUTE_SHELLS] = DataStoreService:GetDataStore(DATA_SHELLS), 
    [ATTRIBUTE_ENERGY_AMMO] = DataStoreService:GetDataStore(DATA_ENERGY_AMMO)
}

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)

local tweenTime = 2
local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    local StatsGui : ScreenGui = player.PlayerGui:WaitForChild("StatsGui")  

    local billboardCapsAmount : TextLabel = StatsGui.Billboard.Caps.BloxyCola.Amount
    local billboardAmmo : Frame = StatsGui.Billboard.Ammo
    local billboardAmmoTypes = {
        ["LightBullets"] = billboardAmmo.LightBullets,
        ["MediumBullets"] = billboardAmmo.MediumBullets,
        ["HeavyBullets"] = billboardAmmo.HeavyBullets,
        ["Shells"] = billboardAmmo.Shells,
        ["EnergyAmmo"] = billboardAmmo.EnergyAmmo,
    }

    --functions for updating gui
    local gainedResourceIndicator : CanvasGroup = StatsGui.StorageButton:FindFirstChild("Gain", true)

    local function gainedResourceEffect(attributeName : string, amountGained : number)
        if amountGained == 0 then return end
        local x : Frame = gainedResourceIndicator:Clone()
        x.Visible = true
        x.Icon.Image = attributeIconMap[attributeName]
        x.Amount.Text = "+" .. tostring(amountGained)
        x.Parent = gainedResourceIndicator.Parent
        TweenService:Create(x, ti, {GroupTransparency = 1}):Play()
        Debris:AddItem(x, tweenTime)
    end

    local function updateCapGui(capsGained : number, newCapAmount : number)
        billboardCapsAmount.Text = newCapAmount
        gainedResourceEffect(ATTRIBUTE_CAPS, capsGained)
    end

    local function updateAmmoGui(ammoType : string, ammoGained : number, newAmmoAmount : number)
        billboardAmmoTypes[ammoType].Amount.Text = newAmmoAmount
        gainedResourceEffect(ammoType, ammoGained)
    end

    --getting saved data
    --[[ moved
    local wasSuccess, currentCaps = pcall(function()
        return PlayerCaps:GetAsync(player.UserId)
    end)
    player:SetAttribute(ATTRIBUTE_CAPS, if currentCaps then currentCaps else 0)
    updateCapGui(0, player:GetAttribute(ATTRIBUTE_CAPS))

    for _, attribute in ammoAttributes do
        local wasSuccess, currentAmmo = pcall(function()
            return DataStores[attribute]:GetAsync(player.UserId)
        end)
        player:SetAttribute(attribute, if currentAmmo then currentAmmo else 0)
        updateAmmoGui(attribute, 0, player:GetAttribute(attribute))
    end
    player:SetAttribute("StatsLoaded", true)
    ]]

    while not player:GetAttribute("StatsLoaded") do
        task.wait()
        --print("loading stats")
    end
    --after stats have loaded, use a for loop to update the gui

    --detecting changes to attributes & updating gui as needed
    local lastAmounts = {
        [ATTRIBUTE_CAPS] = player:GetAttribute(ATTRIBUTE_CAPS),
        [ATTRIBUTE_LIGHT_BULLETS] = player:GetAttribute(ATTRIBUTE_LIGHT_BULLETS), 
        [ATTRIBUTE_MEDIUM_BULLETS] = player:GetAttribute(ATTRIBUTE_MEDIUM_BULLETS), 
        [ATTRIBUTE_HEAVY_BULLETS] = player:GetAttribute(ATTRIBUTE_HEAVY_BULLETS),
        [ATTRIBUTE_SHELLS] = player:GetAttribute(ATTRIBUTE_SHELLS), 
        [ATTRIBUTE_ENERGY_AMMO] = player:GetAttribute(ATTRIBUTE_ENERGY_AMMO)
    }

    player:GetAttributeChangedSignal(ATTRIBUTE_CAPS):Connect(function()
        local newCapAmount = player:GetAttribute(ATTRIBUTE_CAPS)
        local capGain = player:GetAttribute(ATTRIBUTE_CAPS) - lastAmounts[ATTRIBUTE_CAPS]
        --print(tostring(oldCapAmount) .. " + " .. tostring(capGain) .. " = " .. tostring(newCapAmount))
        updateCapGui(capGain, newCapAmount)
        lastAmounts[ATTRIBUTE_CAPS] = newCapAmount
    end)

    for _, attributeName in ammoAttributes do
        player:GetAttributeChangedSignal(attributeName):Connect(function()
            local newAmount = player:GetAttribute(attributeName)
            local gain = player:GetAttribute(attributeName) - lastAmounts[attributeName]
            --print(tostring(oldCapAmount) .. " + " .. tostring(capGain) .. " = " .. tostring(newCapAmount))
            updateAmmoGui(attributeName, gain, newAmount)
            lastAmounts[attributeName] = newAmount
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
            rev_statChangeSound:FireClient(player, ATTRIBUTE_CAPS)
        elseif tagName == TAG_AMMO then
            local numberOfAmmoTypesToGive = math.random(1, #ammoAttributes)
            local clonedTable = table.clone(ammoAttributes)
            for count = 1, numberOfAmmoTypesToGive, 1 do
                local randomAmmoType = clonedTable[math.random(1, #clonedTable)]
                local ammoAmount = math.random(10, 30)
                player:SetAttribute(randomAmmoType, player:GetAttribute(randomAmmoType) + ammoAmount)
            end
            rev_statChangeSound:FireClient(player, "Ammo")
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

