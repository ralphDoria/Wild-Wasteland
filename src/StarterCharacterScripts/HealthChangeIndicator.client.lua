local TweenService = game:GetService("TweenService")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character.Humanoid

local effectsOverlay : ScreenGui = player.PlayerGui:WaitForChild("EffectsOverlay")
effectsOverlay.Enabled = true
local cachedHealth : number = humanoid.Health

local function fadeInFadeOutTween(object)
    return TweenService:Create(
        object, 
        TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, true),
        {GroupTransparency = 0}
    )
end

local function pulseTween(object)
    return TweenService:Create(
        object,
        TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge, true),
        {GroupTransparency = 0}
    )
end

local lowHealthOverlay

humanoid.HealthChanged:Connect(function()
    if humanoid.Health < humanoid.MaxHealth/4 then
        effectsOverlay.Blood.GroupTransparency = 0.7
        lowHealthOverlay = pulseTween(effectsOverlay.Blood)
        lowHealthOverlay:Play()
    else
        if lowHealthOverlay ~= nil then
            lowHealthOverlay:Cancel()
            lowHealthOverlay = nil
            effectsOverlay.Blood.GroupTransparency = 1  
        end
    end

    if humanoid.Health > cachedHealth then
        fadeInFadeOutTween(effectsOverlay.Heal):Play()
    else
        if lowHealthOverlay == nil then
            fadeInFadeOutTween(effectsOverlay.Blood):Play()
        end
    end


    cachedHealth = humanoid.Health
end)