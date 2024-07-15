local ATTRIBUTE_CAPS = "Caps"
local ATTRIBUTE_BULLETS = "Bullets"

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local DataStoreService = game:GetService("DataStoreService")
local DATA_CAPS = "PlayerCaps"
local PlayerCaps = DataStoreService:GetDataStore(DATA_CAPS)

local rev_statChangeSound = game:GetService("ReplicatedStorage"):FindFirstChild("StatChangeSound", true)

local tweenTime = 1
local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local coinCollectSound : Sound = game:GetService("SoundService").CurrencySystem["Coins ka-ching"]
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
    local StatsGui : ScreenGui = player.PlayerGui:WaitForChild("StatsGui")  

    local billboardCapsAmount : TextLabel = StatsGui.Billboard:FindFirstChild("Caps", true).Amount
    local billboardBulletsAmount : TextLabel = StatsGui.Billboard:FindFirstChild("Ammo", true).Amount

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

    local function setBulletsAmount(bullets : number)
        billboardBulletsAmount.Text = tostring(bullets)
    end

    local wasSuccess, currentCaps = pcall(function()
        return PlayerCaps:GetAsync(player.UserId)
    end)
    print(wasSuccess)
    player:SetAttribute(ATTRIBUTE_CAPS, if currentCaps then currentCaps else 0)
    updateCapGui(0, currentCaps)
    player:SetAttribute(ATTRIBUTE_BULLETS, 0)

    local oldCapAmount : number = player:GetAttribute(ATTRIBUTE_CAPS)
    local oldBulletAmount : number = player:GetAttribute(ATTRIBUTE_BULLETS)
    player:GetAttributeChangedSignal(ATTRIBUTE_CAPS):Connect(function()
        local newCapAmount = player:GetAttribute(ATTRIBUTE_CAPS)
        local capGain = player:GetAttribute(ATTRIBUTE_CAPS) - oldCapAmount
        --print(tostring(oldCapAmount) .. " + " .. tostring(capGain) .. " = " .. tostring(newCapAmount))
        updateCapGui(capGain, newCapAmount)
        oldCapAmount = newCapAmount
        rev_statChangeSound:FireClient(player, ATTRIBUTE_CAPS)
    end)

    player:GetAttributeChangedSignal(ATTRIBUTE_BULLETS):Connect(function()
        
    end)
end)



----------------------------------------------------------------
local CollectionService = game:GetService("CollectionService")

for _, taggedInstance in CollectionService:GetTagged("DroppedCurrency") do
    local proxProm : ProximityPrompt = taggedInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
    if proxProm then
        proxProm.Triggered:Connect(function(player)
            proxProm.Enabled = false
            taggedInstance:Destroy()
            local pileValue = math.random(10, 20)
            player:SetAttribute(ATTRIBUTE_CAPS, player:GetAttribute(ATTRIBUTE_CAPS) + pileValue)
        end)
    end
end