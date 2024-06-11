local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local ui : ScreenGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingScreenUI")
local assetCounter : TextLabel = ui:FindFirstChild("assetCounter", true)
local loadingLabel : TextLabel = ui:FindFirstChild("loadingLabel", true)
local loadedSound : Sound = ui:WaitForChild("Piano Short 10 (b)")
local plr = game:GetService("Players").LocalPlayer

if ui.Enabled == false then
    ui.Enabled = true
end

-- Disables the Reset Button
----[ Creates a Loop to make sure that the ResetButtonCallBack works.
local disableResetButton = task.spawn(function()
	repeat 
		local success = pcall(function() 
			StarterGui:SetCore("ResetButtonCallback", false) 
		end)
		task.wait(1)
	until success
end)

local char = plr.Character or plr.CharacterAdded:Wait()
char:WaitForChild("Humanoid").WalkSpeed = 0
char:WaitForChild("Humanoid").JumpHeight = 0
char:WaitForChild("HumanoidRootPart").CFrame = game.Workspace.World.spawnPoints.loadingScreenSpawn.CFrame
plr.RespawnLocation = game.Workspace.World.spawnPoints.loadingScreenSpawn

local fadeTime = 3
local TweenService = game:GetService("TweenService")
local fadeOutGui3 = TweenService:Create(
	loadingLabel,
	TweenInfo.new(fadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
	{TextTransparency = 1}
)
local fadeOutGui2 = TweenService:Create(
	assetCounter,
	TweenInfo.new(fadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
	{TextTransparency = 1}
)
local fadeOutGui1 = TweenService:Create(
	ui:WaitForChild("blackBackground"),
	TweenInfo.new(fadeTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In),
	{BackgroundTransparency = 1}
)

repeat wait() until game:IsLoaded()

local assets = game:GetDescendants()
local maxAssets = #assets

local plr = game:GetService("Players").LocalPlayer
local plrGui : PlayerGui = plr:WaitForChild("PlayerGui")

ui.Parent = plrGui --loading begin

local thread = task.spawn(function()
	local dotCount = 0
	
	while true do
		if dotCount < 3 then
			loadingLabel.Text = loadingLabel.Text .. "."
			dotCount += 1
			task.wait(0.3)
		else
			loadingLabel.Text = "Loading"
			dotCount = 0
			task.wait(0.3)
		end
	end
end)

assetCounter.Text = 0 .. "/" .. maxAssets

for i, assetToLoad in ipairs(assets) do
	ContentProvider:PreloadAsync({assetToLoad})
	assetCounter.Text = i .. "/" .. maxAssets
end

char:WaitForChild("HumanoidRootPart").CFrame = game.Workspace.World.spawnPoints.spawn0.CFrame
plr.RespawnLocation = game.Workspace.World.spawnPoints.spawn0


task.cancel(thread)
loadingLabel.Text = "Loaded!"
char:WaitForChild("Humanoid").WalkSpeed = 16
char:WaitForChild("Humanoid").JumpHeight = 7.2

loadedSound:Play()
fadeOutGui3:Play()
fadeOutGui2:Play()
fadeOutGui1:Play()
fadeOutGui1.Completed:Connect(function()
	ui:Destroy()
end)
task.cancel(disableResetButton)
StarterGui:SetCore("ResetButtonCallback", true) 