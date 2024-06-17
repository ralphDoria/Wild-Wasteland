local player = game.Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local CharacterStatusGui = PlayerGui:WaitForChild("CharacterStatusGui")

local MAXSTAMINA = 100
local currentStamina = MAXSTAMINA
local minRequiredStamina = 15 --this is a percentage
local staminaBar = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaFrame")
local minRequiredStaminaBar = staminaBar:Clone()
minRequiredStaminaBar.Size = UDim2.new(1*(minRequiredStamina/100), 0, 1, 0)
minRequiredStaminaBar.ZIndex = 2
minRequiredStaminaBar.BackgroundColor3 = Color3.new(0, 0, 0)
minRequiredStaminaBar.BackgroundTransparency = 0.8
minRequiredStaminaBar.Parent = staminaBar.Parent
local staminaLabel = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaLabel")