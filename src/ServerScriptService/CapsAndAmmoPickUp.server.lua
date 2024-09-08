local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerStatsInfo = require(ReplicatedStorage:FindFirstChild("PlayerStatsInfo", true))

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)

---------------------------------------------------------------- Code below is for picking up caps/ammo cans & only setting attribute values
local CollectionService = game:GetService("CollectionService")

local TAG_RANDOM_CURRENCY = "DroppedCurrency"
local TAG_RANDOM_AMMO = "DroppedAmmo"
local specificTagNames = {}
for _, v in playerStatsInfo.getAll() do
    table.insert(specificTagNames, v.name)
end

local playSound = game:GetService("ReplicatedStorage"):FindFirstChild("PlayerSoundUtil", true)
local SoundService = game:GetService("SoundService")
local coinCollectSound : Sound = SoundService.CurrencySystem["Coins ka-ching"]
local ammoCollectSound : Sound = SoundService:FindFirstChild("Ammo pickup", true)

local currencyProxProm : ProximityPrompt = ReplicatedStorage:FindFirstChild("BottleCaps", true).ProximityPrompt
local ammoProxProm : ProximityPrompt = ReplicatedStorage:FindFirstChild("AmmoCans", true).ProximityPrompt

local function handleTaggedInstance(tagName, taggedInstance)
    local clonedProxProm : ProximityPrompt
    if tagName == TAG_RANDOM_CURRENCY then
        clonedProxProm = currencyProxProm:Clone()
    elseif tagName == TAG_RANDOM_AMMO then
        clonedProxProm = ammoProxProm:Clone()
    elseif table.find(specificTagNames, tagName) then
        clonedProxProm = currencyProxProm:Clone()
        --[[
            TODO: concatenate tag name w/ specific amount, which is identifiable as an attribute in the tagged instance
        ]]
        clonedProxProm.ObjectText = taggedInstance:GetAttribute("Amount") .. " " .. tagName
    else
        warn("Invalid tag name")
        return
    end
    clonedProxProm.Parent = taggedInstance.PrimaryPart
    clonedProxProm.Enabled = true
    clonedProxProm.Triggered:Connect(function(player)
        currencyProxProm.Enabled = false
        taggedInstance:Destroy()
        if tagName == TAG_RANDOM_CURRENCY then
            local pileValue = math.random(10, 20)
            player:SetAttribute(playerStatsInfo.ATTRIBUTE_CAPS.name, player:GetAttribute(playerStatsInfo.ATTRIBUTE_CAPS.name) + pileValue)
            rev_statChangeSound:FireClient(player, TAG_RANDOM_CURRENCY)
        elseif tagName == TAG_RANDOM_AMMO then
            local numberOfAmmoTypesToGive = math.random(1, #playerStatsInfo.getAmmo())
            local clonedTable = table.clone(playerStatsInfo.getAmmo())
            for count = 1, numberOfAmmoTypesToGive, 1 do
                local randomAmmoType = clonedTable[math.random(1, #clonedTable)].name
                local ammoAmount = math.random(10, 30)
                player:SetAttribute(randomAmmoType, player:GetAttribute(randomAmmoType) + ammoAmount)
            end
            rev_statChangeSound:FireClient(player, TAG_RANDOM_AMMO)
        elseif table.find(specificTagNames, tagName) then
            local pickUpAmount = taggedInstance:GetAttribute("Amount")
            player:SetAttribute(tagName, player:GetAttribute(tagName) + pickUpAmount)
            rev_statChangeSound:FireClient(player, if tagName == "Caps" then TAG_RANDOM_CURRENCY else TAG_RANDOM_AMMO)
        end
    end)
end
for _, taggedInstance in CollectionService:GetTagged(TAG_RANDOM_CURRENCY) do
    handleTaggedInstance(TAG_RANDOM_CURRENCY, taggedInstance)
end
CollectionService:GetInstanceAddedSignal(TAG_RANDOM_CURRENCY):Connect(function(taggedInstance)
    handleTaggedInstance(TAG_RANDOM_CURRENCY, taggedInstance)
end)

for _, taggedInstance in CollectionService:GetTagged(TAG_RANDOM_AMMO) do
    handleTaggedInstance(TAG_RANDOM_AMMO, taggedInstance)
end
CollectionService:GetInstanceAddedSignal(TAG_RANDOM_AMMO):Connect(function(taggedInstance)
    handleTaggedInstance(TAG_RANDOM_AMMO, taggedInstance)
end)

for _, v in playerStatsInfo.getAll() do
    local tagName = v.name
    CollectionService:GetInstanceAddedSignal(tagName):Connect(function(taggedInstance)
        handleTaggedInstance(tagName, taggedInstance)
    end)
end