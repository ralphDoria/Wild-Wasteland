local CollectionService = game:GetService("CollectionService")
local coinCollectSound = game:GetService("SoundService").CurrencySystem["Coins ka-ching"]
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local tweenTime = 1

local ti = TweenInfo.new(tweenTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

for _, taggedInstance in CollectionService:GetTagged("DroppedCurrency") do
    local proxProm : ProximityPrompt = taggedInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
    if proxProm then
        proxProm.Triggered:Connect(function(player)
            local model = taggedInstance
            local pileValue = math.random(10, 20)
            local CurrencySystemUI : ScreenGui = player.PlayerGui.CurrencySystemUI
            local capAmount : TextLabel = CurrencySystemUI:FindFirstChild("capAmount", true)
            local capGain : TextLabel = CurrencySystemUI:FindFirstChild("capGain", true)
            model:Destroy()
            local y : Sound = coinCollectSound:Clone()
            y.Parent = coinCollectSound.Parent
            y:Play() --I'm just trying to implement this quickly since I want to see what the game feels like, but in the future, this needs to be played locally (a remove event is needed)
            Debris:AddItem(y, y.TimeLength)
            capAmount.Text = tonumber(capAmount.Text) + pileValue
            local x : TextLabel = capGain:Clone()
            x.Visible = true
            x.Text = "+" .. tostring(pileValue)
            x.Parent = capGain.Parent
            TweenService:Create(x, ti, {Position = UDim2.new(1, 0, -1, 0)}):Play()
            TweenService:Create(x, ti, {TextTransparency = 1}):Play()
            Debris:AddItem(x, tweenTime)
        end)
    end
end