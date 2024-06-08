local ProximityPromptService = game:GetService("ProximityPromptService")
local squarePPUI = game.ReplicatedStorage:WaitForChild("CustomProximityPromptUI"):WaitForChild("SquareProximityPrompt")

ProximityPromptService.PromptShown:Connect(function(prompt)
	squarePPUI:Clone().Parent = prompt.Parent
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	prompt.Parent:FindFirstChild("customPPUI"):Destroy()
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	prompt.Parent:FindFirstChild("customPPUI").TextLabel.BorderSizePixel = 4
end)