local ProximityPromptService = game:GetService("ProximityPromptService")
local squarePPUI = game.ReplicatedStorage:WaitForChild("CustomProximityPromptUI"):WaitForChild("SquareProximityPrompt")
local HoldToClickGui = require(game:GetService("ReplicatedStorage"):WaitForChild("RojoManaged_RS"):WaitForChild("HoldToClickGui"))

ProximityPromptService.PromptShown:Connect(function(prompt)
	squarePPUI:Clone().Parent = prompt.Parent
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	prompt.Parent:FindFirstChild("SquareProximityPrompt"):Destroy()
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	local customPP = prompt.Parent:FindFirstChild("SquareProximityPrompt")
	customPP.Frame.BackgroundTransparency = 0.5
end)

--[[
***The code below doesn't work because the HoldToClickGui wasn't coded in luau OOP correctly.
	This is a good opportunity to brush up on my Lua OOP
]]
ProximityPromptService.PromptButtonHoldBegan:Connect(function(prompt, playerWhoTriggered)
	local customPP = prompt.Parent:FindFirstChild("SquareProximityPrompt")
	local ProgressBar = HoldToClickGui.new(customPP, prompt.HoldDuration, 2, 2)
	ProgressBar:Start()

	ProximityPromptService.PromptButtonHoldEnded:Once(function(prompt, playerWhoTriggered)
		ProgressBar:End()
	end)
end)