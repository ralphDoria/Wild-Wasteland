local player = game:GetService("Players").LocalPlayer
local humanoid = player.Character:WaitForChild("Humanoid")

local MAXHEALTH = humanoid.MaxHealth
local currentHealth = humanoid.Health -- *this is a number reference, not a property reference, so you have to manually update it
local PlayerGui = player:WaitForChild("PlayerGui")
local CharacterStatusGui = PlayerGui:WaitForChild("CharacterStatusGui")
local healthBar = CharacterStatusGui:WaitForChild("healthDisplay"):WaitForChild("bgFrame"):WaitForChild("healthFrame")
local healthLabel = CharacterStatusGui:WaitForChild("healthDisplay"):WaitForChild("bgFrame"):WaitForChild("healthLabel")

humanoid.HealthChanged:Connect(function()
	currentHealth = humanoid.Health
	local percentHealth = math.clamp(math.round(currentHealth/MAXHEALTH*100), 0, 100)
	healthLabel.Text = "Health: "..percentHealth .. "%"
	healthBar:TweenSize(UDim2.new(math.clamp(currentHealth/MAXHEALTH, 0, 1), 0, 1, 0), "Out", "Linear", 0.1)
end)