local StarterGui = game:GetService("StarterGui")
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
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
local plr = game:GetService("Players").LocalPlayer
plr:SetAttribute("inTitleScreen", true)
local char = plr.Character or plr.CharacterAdded:Wait()
local ff = Instance.new("ForceField")
ff.Parent = char
local inventoryAndHotbar = plr.PlayerGui:WaitForChild("InventoryAndHotbar")
local startScreen : ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("StartScreen")
startScreen.Enabled = true
local Eyelids : ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("Eyelids")
Eyelids.Enabled = false
--SERVICES
local ContentProvider = game:GetService("ContentProvider")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")
local SoundService = game:GetService("SoundService")
local GuiService = game:GetService("GuiService")
--UTILITY
local utility = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility")
local SoundUtil = require(utility:WaitForChild("SoundUtil"))
local playSound = require(utility:WaitForChild("PlaySoundUtil"))
--REFERENCES
local background : Frame = startScreen.background
local loadingScreenElements = {
	mainInfo = startScreen:FindFirstChild("mainInfo", true),
	miscInfo = startScreen:FindFirstChild("miscInfo", true),
	progressCircle = startScreen:FindFirstChild("progressCircle", true),
	gradient = startScreen:FindFirstChild("progressCircle", true):FindFirstChildWhichIsA("UIGradient", true)
}
local titleScreenElements = {
	buttons = startScreen:FindFirstChild("buttons", true),
	logo = startScreen:FindFirstChild("logo", true)
}
local sideScreens = {
	["CONTROLS"] = startScreen.sideScreens.CONTROLS,
	["SETTINGS"] = startScreen.sideScreens.SETTINGS,
	["NOTES"] = startScreen.sideScreens.NOTES
}
--SOUND
local sounds : Folder = startScreen.Sounds
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
local stroke = startScreen.uiModifiers.UIStroke
local corner = startScreen.uiModifiers.UICorner
local function hoverEffect(old, new)
	if old ~= nil then
		old.Size = UDim2.new(1, 0, 0, 50)
		old.TextTransparency = 0.3
	end
	if new ~= nil then
		new.Size = UDim2.new(1, 0, 0, 60)
		new.TextTransparency = 0
	end
end
local function selectEffect(guiObject)
	stroke.Parent = guiObject
	corner.Parent = guiObject
end
local function togglePage(page, toggle : boolean, time : number)
	local tween
	if toggle then
		tween = TweenService:Create(page, TweenInfo.new(time), {Size = UDim2.fromScale(0.8, 1)})
	else
		tween = TweenService:Create(page, TweenInfo.new(time), {Size = UDim2.fromScale(0.8, 0)})
	end
	tween:Play()
	return tween
end
selectEffect(nil)
hoverEffect(nil, nil)

--CHAR PREP
local humanoid = char:WaitForChild("Humanoid")
local hrp = char:WaitForChild("HumanoidRootPart")
hrp.Anchored = true
char.HumanoidRootPart.CFrame = loadingScreenSpawn.CFrame
plr.RespawnLocation = loadingScreenSpawn
--UI PREP
GuiService.TouchControlsEnabled = false --disabled mobile touch controls
loadingScreenElements.mainInfo.Text = "Loading... <br /> 0%"
titleScreenElements.buttons.Position = UDim2.fromScale(-(titleScreenElements.buttons.Size.X.Scale), 0)
for _, v in titleScreenElements do
	v.Visible = false
end
for _, v in loadingScreenElements do
	if v:IsA("GuiObject") then
		v.Visible = true
	end
end
for _, v in sideScreens do
	v.Size = UDim2.fromScale(0.8, 0)
	v.Visible = true
end
--SOUND PREP
ambienceSG.Volume = 0
--LOADING SCREEN STARTED

repeat 
	task.wait() 
until game:IsLoaded()
local assets = game:GetChildren()
local maxAssets = #assets
musicSG.radioEffect.Enabled = false
musicSG.reverb.Enabled = false
SoundUtil.toggleMuffle(musicSG.lowPassFilter, true, 0)
musicSG.pitchShifter.Octave = 0.5
SoundUtil.pitchUp(musicSG.pitchShifter, 2)
music.jazzWaltzA:Play()
loadingScreenElements.progressCircle.Visible = true
loadingScreenElements.mainInfo.Visible = true
loadingScreenElements.miscInfo.Visible = true
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
	loadingScreenElements.mainInfo.Text = "Loading... <br /> " .. tostring(math.round(i/maxAssets * 100)) .. "%"
	--
	if i/maxAssets == 1 then
		loadingScreenElements.gradient.Transparency = NumberSequence.new(0)
	else
		loadingScreenElements.gradient.Transparency = NumberSequence.new({
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
loadingScreenElements.mainInfo.Text = "Loading... <br /> " .. tostring(math.round(1 * 100)) .. "%"	

task.wait(1)
for _, v in loadingScreenElements do
	if v:IsA("GuiObject") then
		v.Visible = false
	end
end
SoundUtil.pitchDown(musicSG.pitchShifter, 1)
local fadeOut = SoundUtil.fadeVolume(music.jazzWaltzA, 0, 1)
fadeOut.Completed:Wait()
music.jazzWaltzA:Pause()
music.jazzWaltzA.Volume = 1
local function nukeFlashingCutscene()
	sounds.fx.nukeSiren:Play()
	task.wait(3)
	SoundUtil.fadeVolume(sounds.fx.nukeSiren, 0, 10)
	background.BackgroundColor3 = Color3.new(1, 1, 1)
	sounds.fx.nukeRumbling:Play()
	local flashing = TweenService:Create(background, 
		TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.InOut, math.huge, true), 
		{BackgroundColor3 = Color3.new(0.7,0.7,0.7)})
	local fading = TweenService:Create(background.blackScreen, TweenInfo.new(6, Enum.EasingStyle.Linear), {Transparency = 0})
	flashing:Play()	
	task.wait(8)
	fading:Play()
	fading.Completed:Wait()
	flashing:Cancel()
	background.BackgroundColor3 = Color3.new(0, 0, 0)
	background.blackScreen.Transparency = 1
	task.wait(1)
end
--nukeFlashingCutscene()

local connections = {}

local isActivated = {
	["CONTROLS"] = false,
	["NOTES"] = false,
	["SETTINGS"] = false,
}

local currentlyHoveringOn = nil
for _, v in titleScreenElements.buttons:GetChildren() do
	if v:IsA("GuiButton") then
		table.insert(
			connections,
			v.MouseEnter:Connect(function()
				playSound(sounds.interface.hover, nil, 0)
				hoverEffect(currentlyHoveringOn, v)
				currentlyHoveringOn = v
			end)
		)
		table.insert(
			connections,
			v.MouseLeave:Connect(function()
				if currentlyHoveringOn == v then
					hoverEffect(currentlyHoveringOn, nil)
					currentlyHoveringOn = nil
				end
			end)
		)
		local time = 0.3
		table.insert(
			connections,
			v.MouseButton1Down:Connect(function()
				playSound(sounds.interface.click, nil, 0)
				if v.Name ~= "PLAY" then
					if not isActivated[v.Name] then
						isActivated[v.Name] = true
						for key, v2 in isActivated do
							if key ~= v.Name and v2 == true then
								isActivated[key] = false
								togglePage(sideScreens[key], false, time)
							end
						end
						SoundUtil.toggleMuffle(musicSG.lowPassFilter, true, time)
						selectEffect(v)
						togglePage(sideScreens[v.Name], true, time)
					else
						isActivated[v.Name] = false
						SoundUtil.toggleMuffle(musicSG.lowPassFilter, false, time)
						selectEffect(nil)
						togglePage(sideScreens[v.Name], false, time)
					end
				else
					for _, v in connections do
						v:Disconnect()
					end
					selectEffect(v)
					for key, v2 in isActivated do
						if key ~= v.Name and v2 == true then
							isActivated[key] = false
							togglePage(sideScreens[key], false, time)
						end
					end
					SoundUtil.toggleMuffle(musicSG.lowPassFilter, false, time)
					SoundUtil.pitchDown(musicSG.pitchShifter, 2)
					local fadeDown = SoundUtil.fadeVolume(music.jazzWaltzA, 0, 2)
					fadeDown.Completed:Once(function()
						music.jazzWaltzA:Stop()
					end)
					local closeButtonsPanel = TweenService:Create(
						titleScreenElements.buttons, 
						TweenInfo.new(3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), 
						{Position = UDim2.fromScale(-(titleScreenElements.buttons.Size.X.Scale), 0)})
					closeButtonsPanel:Play()
					TweenService:Create(titleScreenElements.logo, TweenInfo.new(3, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut), {ImageTransparency = 1}):Play()
					local fadeOut = SoundUtil.fadeVolume(sounds.fx.buzzingLight, 0, 3)
					fadeOut.Completed:Once(function()
						sounds.fx.buzzingLight:Stop()
					end)
					closeButtonsPanel.Completed:Once(function()
						titleScreenElements.buttons.Visible = false
						Eyelids.Enabled = true

						task.wait(1)

						plr:SetAttribute("inTitleScreen", false)
						plr.RespawnLocation = spawn0
						hrp.Anchored = false
						hrp.CFrame = spawn0.CFrame
						StarterGui:SetCore("ResetButtonCallback", true)
						game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
						GuiService.TouchControlsEnabled = true -- reenabled mobile touch controls
						ambienceSG.Volume = 1
						startScreen.Enabled = false
						plr.CameraMode = Enum.CameraMode.LockFirstPerson

						local openUpper = TweenService:Create(Eyelids.upper, TweenInfo.new(2), {Position = UDim2.fromScale(0, -0.6)})
						local openLower = TweenService:Create(Eyelids.lower, TweenInfo.new(2), {Position = UDim2.fromScale(0, 1)})
						openUpper:Play()
						openLower:Play()
						openLower.Completed:Wait()
						plr.CameraMode = Enum.CameraMode.Classic
						task.wait(5)
						local ff = char:FindFirstChildOfClass("ForceField")
						if ff then
							ff:Destroy()
						end
					end)
				end
			end)
		)
	end
end

sounds.fx.buzzingLight.Volume = 0
sounds.fx.buzzingLight:Play()
SoundUtil.fadeVolume(sounds.fx.buzzingLight, 1, 3)
titleScreenElements.logo.ImageTransparency = 1
TweenService:Create(titleScreenElements.logo, TweenInfo.new(3, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut), {ImageTransparency = 0}):Play()
TweenService:Create(titleScreenElements.buttons, TweenInfo.new(3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0, 0)}):Play()
for _, v in titleScreenElements do
	v.Visible = true
end
musicSG.reverb.Enabled = true
musicSG.radioEffect.Enabled = true
SoundUtil.toggleMuffle(musicSG.lowPassFilter, false, 0)
musicSG.pitchShifter.Octave = 1
music.jazzWaltzA:Play()