local player = game:GetService("Players").LocalPlayer
local humanoid = player.Character:WaitForChild("Humanoid")

local MAXHEALTH = humanoid.MaxHealth
local currentHealth = humanoid.Health -- *this is a number reference, not a property reference, so you have to manually update it
local PlayerGui = player.PlayerGui
local CharacterStatusGui = PlayerGui.CharacterStatusGui
local healthBar = CharacterStatusGui.Frame.health.bar.fill
local healthLabel = CharacterStatusGui.Frame.health.percentage

humanoid.HealthChanged:Connect(function()
	currentHealth = humanoid.Health
	local percentHealth = math.clamp(math.round(currentHealth/MAXHEALTH*100), 0, 100)
	healthLabel.Text = percentHealth .. "%"
	healthBar:TweenSize(UDim2.new(math.clamp(currentHealth/MAXHEALTH, 0, 1), 0, 1, 0), "Out", "Linear", 0.1)
end)