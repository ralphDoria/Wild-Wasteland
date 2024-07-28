local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local loadingUI : ScreenGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("LoadingScreenUI")
local assetCounter : TextLabel = loadingUI:FindFirstChild("assetCounter", true)
local loadingLabel : TextLabel = loadingUI:FindFirstChild("loadingLabel", true)
local plr = game:GetService("Players").LocalPlayer

local randomMessages : TextLabel = loadingUI:FindFirstChild("randomMessages", true)
local messages = {
	"plssssss wait :D"
}

local function typewriterEffect(guiLabel : GuiLabel, message : string)

end

local SoundService = game:GetService("SoundService")
local loadingScreenBackgroundMusic = SoundService:WaitForChild("LoadingScreenBackgroundMusic")

local backgroundSongs = {}
for _, v in loadingScreenBackgroundMusic:GetChildren() do
	if v:IsA("Sound") then
		table.insert(backgroundSongs, v)
	end
end
local SFX = {
	finishedLoadingCue1 = SoundService:WaitForChild("ONESHOT FX-Lonely Call Slide"),
	decision = SoundService:WaitForChild("guiSFX"):WaitForChild("OneShot - Menu Decision"),
	cancel = SoundService:WaitForChild("guiSFX"):WaitForChild("OneShot - Menu Cancel"),
	hover = SoundService:WaitForChild("guiSFX"):WaitForChild("minorSelect")
}

local currentSongIndex = math.random(1, #backgroundSongs)
local currentBackgroundSong : Sound = backgroundSongs[currentSongIndex]
local currentFinishedLoadingCue : Sound = SFX.finishedLoadingCue1

local soundSettingButtons = {
	soundIcon = loadingUI:FindFirstChild("soundIcon", true),
	rightArrow = loadingUI:FindFirstChild("rightArrow", true),
	leftArrow = loadingUI:FindFirstChild("leftArrow", true),
	songTitle = loadingUI:FindFirstChild("songTitle", true)
}

local Debris = game:GetService("Debris")

local function playSound(sound : Sound)
	local x = sound:Clone()
	x.Parent = sound.Parent
	x:Play()
	Debris:AddItem(x, x.TimeLength)
end

local connections = {}

for _, v in soundSettingButtons	 do
	if v:IsA("GuiButton") then
		table.insert(connections, 
		v.MouseEnter:Connect(function()
			playSound(SFX.hover)
			v.BackgroundTransparency = 0.5
		end))
		table.insert(connections, 
		v.MouseLeave:Connect(function()
			v.BackgroundTransparency = 1
		end))
	end
end

local muted = false
currentBackgroundSong.Volume = 0.5
soundSettingButtons.songTitle.Text = "\"" .. currentBackgroundSong.Name .. "\""
soundSettingButtons.soundIcon.Image = soundSettingButtons.soundIcon:WaitForChild("fullVolume").Texture

table.insert(connections,
soundSettingButtons.soundIcon.MouseButton1Click:Connect(function()
	if muted then
		playSound(SFX.decision)
		muted = false
		currentBackgroundSong.Volume = 0.5
		soundSettingButtons.songTitle.Text = "\"" .. currentBackgroundSong.Name .. "\""
		soundSettingButtons.soundIcon.Image = soundSettingButtons.soundIcon:WaitForChild("fullVolume").Texture
	else
		playSound(SFX.cancel)
		muted = true
		currentBackgroundSong.Volume = 0
		soundSettingButtons.songTitle.Text = "[Muted]"
		soundSettingButtons.soundIcon.Image = soundSettingButtons.soundIcon:WaitForChild("mute").Texture
	end
end))

table.insert(connections,
soundSettingButtons.rightArrow.MouseButton1Click:Connect(function()
	currentBackgroundSong:Stop()
	playSound(SFX.decision)
	currentSongIndex += 1
	if currentSongIndex > #backgroundSongs then
		currentSongIndex = 1
	end
	currentBackgroundSong = backgroundSongs[currentSongIndex]
	soundSettingButtons.songTitle.Text = "\"" .. currentBackgroundSong.Name .. "\""
	currentBackgroundSong:Play()
end))

table.insert(connections,
soundSettingButtons.leftArrow.MouseButton1Click:Connect(function()
	currentBackgroundSong:Stop()
	playSound(SFX.decision)
	currentSongIndex -= 1
	if currentSongIndex < 1 then
		currentSongIndex = #backgroundSongs
	end
	currentBackgroundSong = backgroundSongs[currentSongIndex]
	soundSettingButtons.songTitle.Text = "\"" .. currentBackgroundSong.Name .. "\""
	currentBackgroundSong:Play()
end))

game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
--------------------------

local spawnPoints = game.Workspace:FindFirstChild("spawnPoints", true)
local loadingScreenSpawn = spawnPoints:WaitForChild("loadingScreenSpawn")
local spawn0 = spawnPoints:WaitForChild("spawn0")

local char = plr.Character or plr.CharacterAdded:Wait()
char:WaitForChild("Humanoid").WalkSpeed = 0
char:WaitForChild("Humanoid").JumpHeight = 0
char:WaitForChild("HumanoidRootPart").CFrame = loadingScreenSpawn.CFrame
plr.RespawnLocation = loadingScreenSpawn

currentBackgroundSong:Play()

local function fadeAudio(sound : Sound, endVolume : number, fadeTime : number)
	local originalVolume = sound.Volume
	--assert(sound.Volume ~= endVolume, "endVolume parameter needs to be different from current sound volume")
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
	return tweens[1]
end

loadingUI.Enabled = true
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

loadingUI.Parent = plrGui --loading begin

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

assetCounter.Text = "0%"

print("skipping loading screen")
--[[
if not RunService:IsStudio() then
	for i, assetToLoad in ipairs(assets) do
		ContentProvider:PreloadAsync({assetToLoad})
		assetCounter.Text = tostring(math.round(i/maxAssets * 100)) .. "%"
	end
else
	print("testing in studio")
end
]]

char:WaitForChild("HumanoidRootPart").CFrame = spawn0.CFrame
plr.RespawnLocation = spawn0


task.cancel(thread)
loadingLabel.Text = "LOADED"
char:WaitForChild("Humanoid").WalkSpeed = StarterPlayer.CharacterWalkSpeed
char:WaitForChild("Humanoid").JumpHeight = StarterPlayer.CharacterJumpHeight

for _, connection in pairs(connections) do
	connection:Disconnect()
	connection = nil
end

fadeAudio(currentBackgroundSong, 0, 2)
currentBackgroundSong:Stop()
currentFinishedLoadingCue:Play()
local tweenInfo = TweenInfo.new(currentFinishedLoadingCue.TimeLength, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
fadeOutGuis(
	{soundSettingButtons.soundIcon, loadingUI:FindFirstChild("Wallpaper", true)},
	tweenInfo,
	{ImageTransparency = 1}
)
local lastTween = fadeOutGuis(
	{loadingLabel, assetCounter, soundSettingButtons.leftArrow, soundSettingButtons.rightArrow, soundSettingButtons.songTitle, randomMessages},
	tweenInfo,
	{TextTransparency = 1}
)
lastTween.Completed:Wait()
loadingUI:Destroy()

StarterGui:SetCore("ResetButtonCallback", true)