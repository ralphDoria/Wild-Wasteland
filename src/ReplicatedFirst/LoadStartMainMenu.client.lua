--print("Started Running lsmMenu LocalScript")
--Of utmost importance:
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
plr:SetAttribute("inTitleScreen", true) --for inventory gui to hold off on intializing inventory system
local lsmMenu : ScreenGui = game:GetService("ReplicatedFirst").LoadStartMainMenu
lsmMenu.Parent = plr.PlayerGui
-- print("lsmMenu ScreenGui parented")
local loadingScreenElements = {
	mainInfo = lsmMenu:FindFirstChild("mainInfo", true),
	miscInfo = lsmMenu:FindFirstChild("miscInfo", true),
	progressCircle = lsmMenu:FindFirstChild("progressCircle", true),
	gradient = lsmMenu:FindFirstChild("progressCircle", true):FindFirstChildWhichIsA("UIGradient", true)
}
local titleScreenElements = {
	buttons = lsmMenu:FindFirstChild("buttons", true),
	logo = lsmMenu:FindFirstChild("logo", true)
}
local sideScreens = {
	["CONTROLS"] = lsmMenu.sideScreens.CONTROLS,
	["SETTINGS"] = lsmMenu.sideScreens.SETTINGS,
	["NOTES"] = lsmMenu.sideScreens.NOTES
}
local background : Frame = lsmMenu.background
local stroke = lsmMenu.uiModifiers.UIStroke
local corner = lsmMenu.uiModifiers.UICorner
local organizer = require(script.Parent.organizer)
organizer.init(titleScreenElements, loadingScreenElements, sideScreens, stroke, corner)
local GuiService = game:GetService("GuiService")

--UI PREP
background.BackgroundTransparency = 0
GuiService.TouchControlsEnabled = false --disabled mobile touch controls
loadingScreenElements.mainInfo.Text = "Loading... <br /> 0%"
organizer.toggleButtonsPanel(false, 0)
organizer.toggleGuiVisibilityIn(titleScreenElements, false)
organizer.toggleGuiVisibilityIn(loadingScreenElements, true)
for _, v in sideScreens do
	organizer.togglePage(v, false, 0)
	v.Visible = true
end

--ALL CODE ABOVE THIS POINT RUNS WITH NO YIELDING

local char = plr.Character or plr.CharacterAdded:Wait()
local ff = Instance.new("ForceField")
ff.Parent = char
local inventoryAndHotbar = plr.PlayerGui:WaitForChild("InventoryAndHotbar")
lsmMenu.Enabled = true
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
--REFERENCES
local forModal : TextButton = lsmMenu.ForModal
--UTILITY
local utility = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility")
local SoundUtil = require(utility:WaitForChild("SoundUtil"))
local playSound = require(utility:WaitForChild("PlaySoundUtil"))
--SOUND
local sounds : Folder = lsmMenu.Sounds
local music = {
	halloween = sounds.music["Halloween Horrors Waltz"],
	jazzWaltzA = sounds.music["Jazz Waltz (a)"],
	mapleLeafRag = sounds.music["Maple Leaf Rag"]
}
local masterSG : SoundGroup = SoundService:WaitForChild("0 - Master")
local musicSG : SoundGroup = masterSG:WaitForChild("Music")
local gameSG : SoundGroup = masterSG:WaitForChild("Game")
local ambienceSG : SoundGroup = gameSG:WaitForChild("Ambience")
local interfaceSG : SoundGroup = masterSG:WaitForChild("Interface")
local menuSG : SoundGroup = masterSG:WaitForChild("Menu")
local soundGroups = {
	master = masterSG,
	music = musicSG,
	ambience = ambienceSG,
	game = gameSG,
	interface = interfaceSG,
	menu = menuSG
}
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
organizer.selectEffect(nil)
organizer.hoverEffect(nil, nil)

--SOUND PREP
for _, sg in soundGroups do
	sg.Volume = 0
end
soundGroups.master.Volume = 1
soundGroups.menu.Volume = 1
soundGroups.music.Volume = 0.3
soundGroups.interface.Volume = 1
--CHAR PREP
local hrp = char:WaitForChild("HumanoidRootPart")
hrp.Anchored = true
char.HumanoidRootPart.CFrame = loadingScreenSpawn.CFrame
plr.RespawnLocation = loadingScreenSpawn

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
local Icon = require(ReplicatedStorage:WaitForChild("NonRojoManaged"):WaitForChild("TopbarPlus"):WaitForChild("Icon"))

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
organizer.toggleGuiVisibilityIn(loadingScreenElements, false)
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
-- nukeFlashingCutscene()

local connections = {}

local currentlyHoveringOn = nil

for _, button in titleScreenElements.buttons:GetChildren() do

	if not button:IsA("GuiButton") then continue end

	--hover effects
	table.insert(
		connections,
		button.MouseEnter:Connect(function()
			playSound(sounds.interface.hover, nil, 0)
			organizer.hoverEffect(currentlyHoveringOn, button)
			currentlyHoveringOn = button
		end)
	)
	table.insert(
		connections,
		button.MouseLeave:Connect(function()
			if currentlyHoveringOn == button then
				organizer.hoverEffect(currentlyHoveringOn, nil)
				currentlyHoveringOn = nil
			end
		end)
	)

	--button functionality
	local time = 0.3
	table.insert(
		connections,
		button.MouseButton1Down:Connect(function()
			playSound(sounds.interface.click, nil, 0)
			if button.Name ~= "PLAY" then
				if not organizer.pageStatuses[button.Name] then
					SoundUtil.toggleMuffle(musicSG.lowPassFilter, true, time)
					organizer.selectEffect(button)
					organizer.closeAllPagesExcept(sideScreens[button.Name], 0.1)
					organizer.togglePage(sideScreens[button.Name], true, time)
				else
					SoundUtil.toggleMuffle(musicSG.lowPassFilter, false, time)
					organizer.selectEffect(nil)
					organizer.togglePage(sideScreens[button.Name], false, time)
				end
			else
				--PLAY BUTTON IS CLICKED
				organizer.toggleButtonsInteractable(false)
				SoundUtil.toggleMuffle(musicSG.lowPassFilter, false, time)
				SoundUtil.pitchDown(musicSG.pitchShifter, 2)
				local fadeDown = SoundUtil.fadeVolume(music.jazzWaltzA, 0, 2)
				fadeDown.Completed:Once(function()
					music.jazzWaltzA:Stop()
				end)
				local fadeOut = SoundUtil.fadeVolume(sounds.fx.buzzingLight, 0, 3)
				fadeOut.Completed:Once(function()
					sounds.fx.buzzingLight:Stop()
				end)
				--UI
				organizer.selectEffect(button)
				organizer.closeAllPagesExcept(nil, 0.1)
				organizer.tweenLogoTransparency(1, 3)
				local closingButtonsPanel = organizer.toggleButtonsPanel(false, 3)
				closingButtonsPanel.Completed:Once(function()
					organizer.selectEffect(nil)
					button:Destroy()
					Eyelids.Enabled = true

					task.wait(1)

					plr:SetAttribute("inTitleScreen", false)
					plr.RespawnLocation = spawn0
					hrp.Anchored = false
					hrp.CFrame = spawn0.CFrame
					StarterGui:SetCore("ResetButtonCallback", true)
					game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
					GuiService.TouchControlsEnabled = true -- reenabled mobile touch controls
					--turning up volume again
					for _, sg in soundGroups do
						sg.Volume = 1
					end
					soundGroups.music.Volume = 0.3

					background.BackgroundTransparency = 1
					titleScreenElements.buttons.Visible = true
					plr.CameraMode = Enum.CameraMode.LockFirstPerson

					local openUpper = TweenService:Create(Eyelids.upper, TweenInfo.new(2), {Position = UDim2.fromScale(0, -0.6)})
					local openLower = TweenService:Create(Eyelids.lower, TweenInfo.new(2), {Position = UDim2.fromScale(0, 1)})
					openUpper:Play()
					openLower:Play()
					openLower.Completed:Wait()
					plr.CameraMode = Enum.CameraMode.Classic

					organizer.toggleButtonsInteractable(true)
					local menuIcon = Icon.new()
					menuIcon
						:setLabel("Settings")
						:setImage(119890863099288, "Deselected")
						:setImage(124329776276328, "Selected")
						:setCaption("Press M")
						:bindToggleKey(Enum.KeyCode.M)
					local menuTransitionTime = 0.5
					local fadeInBackground = TweenService:Create(
						background, 
						TweenInfo.new(menuTransitionTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
						{Transparency = 0.1})
					local fadeOutBackground = TweenService:Create(
						background, 
						TweenInfo.new(menuTransitionTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out),
						{Transparency = 1})
					menuIcon.selected:Connect(function()
						print("menu icon selected")
						forModal.Modal = true
						organizer.toggleButtonsPanel(true, menuTransitionTime)
						organizer.tweenLogoTransparency(0, menuTransitionTime)
						fadeInBackground:Play()
						SoundUtil.toggleMuffle(soundGroups.master.lowPassFilter, true, menuTransitionTime)
					end)
					menuIcon.deselected:Connect(function()
						print("menu icon deselected")
						forModal.Modal = false
						organizer.toggleButtonsPanel(false, menuTransitionTime)
						fadeOutBackground:Play()
						SoundUtil.toggleMuffle(soundGroups.master.lowPassFilter, false, menuTransitionTime)
						organizer.closeAllPagesExcept(nil, menuTransitionTime)
						organizer.selectEffect(nil)
						organizer.tweenLogoTransparency(1, menuTransitionTime)
					end)

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

sounds.fx.buzzingLight.Volume = 0
sounds.fx.buzzingLight:Play()
SoundUtil.fadeVolume(sounds.fx.buzzingLight, 1, 3)
titleScreenElements.logo.ImageTransparency = 1
organizer.tweenLogoTransparency(0, 3)
organizer.toggleButtonsPanel(true, 3)
for _, v in titleScreenElements do
	v.Visible = true
end
musicSG.reverb.Enabled = true
musicSG.radioEffect.Enabled = true
SoundUtil.toggleMuffle(musicSG.lowPassFilter, false, 0)
musicSG.pitchShifter.Octave = 1
music.jazzWaltzA:Play()