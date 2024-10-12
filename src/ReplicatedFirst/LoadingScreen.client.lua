--SERVICES
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local plr = game:GetService("Players").LocalPlayer
local char = plr.Character or plr.CharacterAdded:Wait()
--REFERENCES
local inventoryAndHotbar = plr.PlayerGui:WaitForChild("InventoryAndHotbar")
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
local titleScreen : ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("TitleScreen")
local mainFrame : Frame = titleScreen.Main
local mainInfo : TextBox = titleScreen:FindFirstChild("mainInfo", true)
local miscInfo : TextBox = titleScreen:FindFirstChild("miscInfo", true)
local circle : Frame = titleScreen:FindFirstChild("circle", true)
local gradient : UIGradient = circle:FindFirstChild("UIGradient", true)
local buttons : Frame = titleScreen:FindFirstChild("Buttons", true)
local Logo : ImageLabel = titleScreen:FindFirstChild("Logo", true)
	--SOUND
local sounds : Folder = titleScreen.Sounds
local music = {
	halloween = sounds.music["Halloween Horrors Waltz"],
	jazzWaltzA = sounds.music["Jazz Waltz (a)"],
	mapleLeafRag = sounds.music["Maple Leaf Rag"]
}
local masterSG : SoundGroup = SoundService:WaitForChild("0 - Master")
local musicSG : SoundGroup = masterSG:WaitForChild("Music")
local ambienceSG : SoundGroup = masterSG:WaitForChild("Ambience")
	--SPAWNS
local spawnPoints = game.Workspace:FindFirstChild("spawnPoints", true)
local loadingScreenSpawn = spawnPoints:WaitForChild("loadingScreenSpawn")
local spawn0 = spawnPoints:WaitForChild("spawn0")
--LOCAL FIELDS
local tips = {
	"slots are draggable",
	""
}
--------------------------------------------------------------------------------------------------------

local connections = {}

--PREPARATIONS FOR LOADING SCREEN
game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
char.Humanoid.WalkSpeed = 0
char.Humanoid.JumpHeight = 0
char.HumanoidRootPart.CFrame = loadingScreenSpawn.CFrame
plr.RespawnLocation = loadingScreenSpawn
--------------------------

--SOUND EFFECTS
local function toggleMuffle(equalizer : EqualizerSoundEffect, toggle : boolean, transitionTime : number)
	if not equalizer.Enabled then equalizer.Enabled = true end
	local ti : TweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Linear)
	if toggle then
		TweenService:Create(equalizer, ti, {HighGain = -80}):Play()
		TweenService:Create(equalizer, ti, {MidGain = -80}):Play()
		TweenService:Create(equalizer, ti, {LowGain = 10}):Play()
	else
		TweenService:Create(equalizer, ti, {HighGain = 0}):Play()
		TweenService:Create(equalizer, ti, {MidGain = 0}):Play()
		TweenService:Create(equalizer, ti, {LowGain = 0}):Play()
	end
end

--[[
local function trackSwitchEffect(pitch : PitchShiftSoundEffect, from : Sound, to : Sound)
	if not pitch.Enabled then pitch.Enabled = true end
	local tweenTime = 0.2
	local tween2 = TweenService:Create(pitch, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Octave = 0.25})
	local tween1 = TweenService:Create(pitch, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Octave = 1.5})
	local tween3 = TweenService:Create(pitch, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {Octave = 1})
	tween1.Completed:Once(function()
		to:Play()
		task.wait(tweenTime)
		tween2:Play()
	end)
	tween2.Completed:Once(function()
		from:Stop()
		task.wait(tweenTime)
		tween3:Play()
	end)
	tween1:Play()
end
]]

local function pitchDown(pitch : PitchShiftSoundEffect, time : number)
	pitch.Enabled = true
	local ti = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local targetPitch = 0.5
	if pitch.Octave == targetPitch then
		warn("effect is already pitched down")
	end
	local tween = TweenService:Create(pitch, ti, {Octave = targetPitch})
	tween:Play()
	return tween
end

local function pitchUp(pitch : PitchShiftSoundEffect, time : number)
	pitch.Enabled = true
	local ti = TweenInfo.new(time, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	local targetPitch = 1
	if pitch.Octave == targetPitch then
		warn("effect is already pitched up")
	end
	local tween = TweenService:Create(pitch, ti, {Octave = targetPitch})
	tween:Play()
	return tween
end

local function fadeVolume(sound : Sound, targetVolume : number, time : number)
	if targetVolume == sound.Volume then
		warn("Sound's volume is already at target volume")
	end
	TweenService:Create(sound, TweenInfo.new(time, Enum.EasingStyle.Linear), {Volume = targetVolume}):Play()
end

local stroke = titleScreen.uiModifiers.UIStroke
local corner = titleScreen.uiModifiers.UICorner
local function hoverEffect(guiObject)
	stroke.Parent = guiObject
	corner.Parent = guiObject
end
hoverEffect(nil)

--------------------------------------------------------------------------------------------

titleScreen.Enabled = true
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

ambienceSG.Volume = 0
--LOADING SCREEN STARTED
repeat 
	task.wait() 
until game:IsLoaded()
inventoryAndHotbar.Enabled = false
local assets = game:GetChildren()
local maxAssets = #assets
mainInfo.Text = "Loading... <br /> " .. tostring(0) ..  "/" .. tostring(maxAssets)
musicSG.radioEffect.Enabled = false
musicSG.reverb.Enabled = false
toggleMuffle(musicSG.lowPassFilter, true, 0)
musicSG.pitchShifter.Octave = 0.5
pitchUp(musicSG.pitchShifter, 2)
music.jazzWaltzA:Play()
circle.Visible = true
mainInfo.Visible = true
miscInfo.Visible = true
task.wait(1)

--[[
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

]]

for i, v in ipairs(assets) do
	ContentProvider:PreloadAsync({v})
	mainInfo.Text = "Loading... <br /> " .. tostring(math.round(i/maxAssets * 100)) .. "% of " .. tostring(maxAssets) .. " assets"
	--
	if i/maxAssets == 1 then
		gradient.Transparency = NumberSequence.new(0)
	else
		gradient.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(i/maxAssets, 1),
			NumberSequenceKeypoint.new(1, 1)
		 })
	end
end
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

--FINISHED LOADING
mainInfo.Text = "Loading... <br /> " .. tostring(math.round(1 * 100)) .. "% of " .. tostring(maxAssets) .. " assets"

task.wait(1)
circle.Visible = false
mainInfo.Visible = false
miscInfo.Visible = false
local tween = pitchDown(musicSG.pitchShifter, 1)
tween.Completed:Wait()
music.jazzWaltzA:Pause()
sounds.fx.nukeSiren:Play()
task.wait(3)
fadeVolume(sounds.fx.nukeSiren, 0, 10)
mainFrame.BackgroundColor3 = Color3.new(1, 1, 1)
sounds.fx.nukeRumbling:Play()
local flashing = TweenService:Create(mainFrame, 
	TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut, math.huge, true), 
	{BackgroundColor3 = Color3.new(0.7,0.7,0.7)})
local fading = TweenService:Create(mainFrame.blackScreen, TweenInfo.new(6, Enum.EasingStyle.Linear), {Transparency = 0})
flashing:Play()	
task.wait(8)
fading:Play()
fading.Completed:Wait()
flashing:Cancel()
mainFrame.BackgroundColor3 = Color3.new(0, 0, 0)
mainFrame.blackScreen.Transparency = 1
task.wait(1)

local currentlyHoveringOn = nil
for _, v in buttons:GetChildren() do
	if v:IsA("GuiButton") then
		v.MouseEnter:Connect(function()
			playSound(sounds.interface.hover, nil, 0)
			hoverEffect(v)
			currentlyHoveringOn = v
		end)
		v.MouseLeave:Connect(function()
			if currentlyHoveringOn == v then
				currentlyHoveringOn = nil
				hoverEffect(nil)
			end
		end)
		v.MouseButton1Down:Connect(function()
			playSound(sounds.interface.click, nil, 0)
			toggleMuffle(musicSG.lowPassFilter, true, 0.5)
		end)
	end
end

sounds.fx.buzzingLight.Volume = 0
sounds.fx.buzzingLight:Play()
fadeVolume(sounds.fx.buzzingLight, 1, 3)
Logo.ImageTransparency = 1
Logo.Visible = true
TweenService:Create(Logo, TweenInfo.new(3, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
buttons.Position = UDim2.fromScale(-(buttons.Size.X.Scale), 0)
buttons.Visible = true --TWEEN THIS
TweenService:Create(buttons, TweenInfo.new(3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, 0)}):Play()
musicSG.reverb.Enabled = true
musicSG.radioEffect.Enabled = true
toggleMuffle(musicSG.lowPassFilter, false, 0)
musicSG.pitchShifter.Octave = 1
music.jazzWaltzA:Play()

char:WaitForChild("HumanoidRootPart").CFrame = spawn0.CFrame
plr.RespawnLocation = spawn0

--[[
char.Humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
char.Humanoid.JumpHeight = StarterPlayer.CharacterJumpHeight
StarterGui:SetCore("ResetButtonCallback", true)
game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
ambienceSG.Volume = 1
]]