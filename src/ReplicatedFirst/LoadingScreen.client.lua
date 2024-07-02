local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local ui : ScreenGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingScreenUI")
local assetCounter : TextLabel = ui:FindFirstChild("assetCounter", true)
local loadingLabel : TextLabel = ui:FindFirstChild("loadingLabel", true)
local plr = game:GetService("Players").LocalPlayer

local spawnPoints = game.Workspace:FindFirstChild("spawnPoints", true)
local loadingScreenSpawn = spawnPoints:WaitForChild("loadingScreenSpawn")
local spawn0 = spawnPoints:WaitForChild("spawn0")

local SFX = {
	backgroundMusic = ui:WaitForChild("SFX"):WaitForChild("Lonely Christmas 2"),
	finishedLoadingCue1 = ui:WaitForChild("SFX"):WaitForChild("ONESHOT FX-Lonely Call Slide"),
	finishedLoadingCue2 = ui:WaitForChild("SFX"):WaitForChild("Piano Short 10 (b)"),
	desertAmbience = workspace:WaitForChild("Desert Ambience")
}

local currentBackgroundMusic : Sound = SFX.backgroundMusic
local currentFinishedLoadingCue : Sound = SFX.finishedLoadingCue1

local char = plr.Character or plr.CharacterAdded:Wait()
char:WaitForChild("Humanoid").WalkSpeed = 0
char:WaitForChild("Humanoid").JumpHeight = 0
char:WaitForChild("HumanoidRootPart").CFrame = loadingScreenSpawn.CFrame
plr.RespawnLocation = loadingScreenSpawn

SFX.desertAmbience:Stop()
currentBackgroundMusic:Play()

local function fadeAudio(sound : Sound, endVolume : number, fadeTime : number)
	local originalVolume = sound.Volume
	assert(sound.Volume ~= endVolume, "endVolume parameter needs to be different from current sound volume")
	repeat
		if endVolume > originalVolume then
			local difference = endVolume - originalVolume
			local divided = difference/fadeTime
			sound.Volume = math.clamp(sound.Volume + task.wait()*divided, originalVolume, endVolume)
		else
			local difference = originalVolume - endVolume
			local divided = difference/fadeTime
			sound.Volume = math.clamp(sound.Volume - task.wait()*divided, endVolume, originalVolume)
		end
	until sound.Volume == endVolume
end

local function fadeOutGuis(guiTable, tweenInfo : TweenInfo, propertyToTween)
	local tweens = {}
	for _, gui in guiTable do
		assert(gui:IsA("GuiBase"), "guiTable contains non-guis")
		table.insert(
			tweens,
			TweenService:Create(gui, tweenInfo, propertyToTween)
		)
	end
	for _, tween in tweens do
		tween:Play()
	end
	tweens[1].Completed:Wait()
	return
end

ui.Enabled = true
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)

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

if not RunService:IsStudio() then
	for i, assetToLoad in ipairs(assets) do
		ContentProvider:PreloadAsync({assetToLoad})
		assetCounter.Text = i .. "/" .. maxAssets
	end
else
	print("testing in studio")
end



char:WaitForChild("HumanoidRootPart").CFrame = spawn0.CFrame
plr.RespawnLocation = spawn0


task.cancel(thread)
loadingLabel.Text = "Loaded!"
char:WaitForChild("Humanoid").WalkSpeed = StarterPlayer.CharacterWalkSpeed
char:WaitForChild("Humanoid").JumpHeight = StarterPlayer.CharacterJumpHeight

fadeAudio(SFX.backgroundMusic, 0, 2)
currentBackgroundMusic:Stop()
currentFinishedLoadingCue:Play()
SFX.desertAmbience:Play()
local tweenInfo = TweenInfo.new(currentFinishedLoadingCue.TimeLength, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
TweenService:Create(ui:WaitForChild("blackBackground"), tweenInfo, {BackgroundTransparency = 1}):Play()
fadeOutGuis(
	{loadingLabel, assetCounter},
	tweenInfo,
	{TextTransparency = 1}
)
ui:Destroy()
task.cancel(disableResetButton)

StarterGui:SetCore("ResetButtonCallback", true) 