local ProximityPromptService = game:GetService("ProximityPromptService")
local ppInstances = game:GetService("ReplicatedStorage").ProxPromInstances
local highlight = ppInstances.Highlight

ProximityPromptService.PromptShown:Connect(function(prompt)
	local tool = prompt:FindFirstAncestorOfClass("Tool")
	if tool then
		highlight:Clone().Parent = tool
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	local tool = prompt:FindFirstAncestorOfClass("Tool")
	if tool then
		local highlight = tool:FindFirstChildOfClass("Highlight")
		if highlight then
			highlight:Destroy()
		end
	end
end)



--[[ OLD CODE for custom proximity prompts
local ProximityPromptService = game:GetService("ProximityPromptService")
local squarePPUI = game.ReplicatedStorage:WaitForChild("CustomProximityPromptUI"):WaitForChild("SquareProximityPrompt")
local HoldToClickGui = require(game:GetService("ReplicatedStorage"):WaitForChild("RojoManaged_RS"):WaitForChild("HoldToClickGui"))

ProximityPromptService.PromptShown:Connect(function(prompt)
	squarePPUI:Clone().Parent = prompt.Parent
	local ProgressBar = nil
	if prompt:GetAttribute("Initialized") == nil then
		prompt:SetAttribute("Initialized", true)
		local customPP = prompt.Parent:FindFirstChild("SquareProximityPrompt")
		local pb : Frame = customPP:WaitForChild("Frame"):WaitForChild("ProgressBar")
		local ProgressBar = HoldToClickGui.new(pb, prompt.HoldDuration, 2, 2)
		prompt.PromptButtonHoldBegan:Connect(function()
			ProgressBar:Start()
		end)
		prompt.PromptButtonHoldEnded:Connect(function()
			ProgressBar:End()
		end)
	end
end)

ProximityPromptService.PromptHidden:Connect(function(prompt)
	prompt.Parent:FindFirstChild("SquareProximityPrompt"):Destroy()
	prompt:SetAttribute("Initialized", nil)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	local customPP = prompt.Parent:FindFirstChild("SquareProximityPrompt")
	customPP.Frame.BackgroundTransparency = 0.5
end)
]]