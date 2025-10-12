local ButtonsPanelManager = require("./Components/ButtonsPanelManager")
local RightPanelManager = require("./Components/RightPanelManager")
local References_MainMenu = require("./Components/References_MainMenu")
local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)

local state: "TitleScreen" | "GameMenu" = "TitleScreen" 
local MainMenuManager = {initialied = false, isReset = false}

MainMenuManager.menuIcon = nil

function MainMenuManager.init(onPlayButtonClicked: () -> (), onTitleScreenFadingOut: () -> ())
	References_MainMenu.SoundGroupManager.muteAllExcept(References_MainMenu.SoundGroupManager.soundGroups.music)
	References_MainMenu.SoundGroupManager.soundGroups.master.Volume = 1 -- LoadingScreenManager mutes master volume
	MainMenuManager.reset()
	References_MainMenu.MainMenu.Parent = References_MainMenu.playerGui
	ButtonsPanelManager.connectButtonEvents({
		play = function()
			print("Play button clicked")
			onPlayButtonClicked()
			MainMenuManager.closeTitleScreen()
			References_MainMenu.SoundGroupManager.volumeToDefault(1)
			onTitleScreenFadingOut()
		end,
		controls = function()
			print("Controls button clicked")
		end,
		settings = function()
			print("Settings button clicked")
		end,
		notes = function()
			print("Notes button clicked")
		end,
	})

	MainMenuManager.menuIcon = References_MainMenu.TopBarPlusIcon.new()
	MainMenuManager.menuIcon
		:setLabel("Menu")
		:setImage(119890863099288, "Deselected")
		:setImage(124329776276328, "Selected")
		:setCaption("Press M")
		:bindToggleKey(Enum.KeyCode.M)

	MainMenuManager.menuIcon.selected:Connect(function()
		print("menu icon selected")
		ButtonsPanelManager.toggleButtons(true, 0.5)
		-- MainMenuManager.openGameMenuVersion()
	end)
	MainMenuManager.menuIcon.deselected:Connect(function()
		print("menu icon deselected")
		ButtonsPanelManager.toggleButtons(false, 0.5)
		-- MainMenuManager.closeGameMenu()
	end)
	MainMenuManager.menuIcon:setEnabled(false)

	MainMenuManager.initialized = true
end

function MainMenuManager.setState(state: number)

end


function MainMenuManager.reset()
	References_MainMenu.Frame.Transparency = 0
	References_MainMenu.Frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

	--hide side References_MainMenu.panels
	MainMenuManager.toggleSlideSidePanels(false, 0)
	--make center panel invisible
	References_MainMenu.CenterPanel.GroupTransparency = 1
	
	for _, v in References_MainMenu.rightPanelTbl do
		v.Visible = false
	end
	ButtonsPanelManager.toggleButtons(false, 0)
	References_MainMenu.MainMenu.Enabled = true

	MainMenuManager.isReset = true
end

function MainMenuManager.playNukeScene()
	return Promise.new(function(resolve, reject, onCancel)
		-- registering cancel callback
		onCancel(function()
			-- cleanup
		end)

		MainMenuManager.resetIfNeeded()
		MainMenuManager.isReset = false
		local nukeSiren = References_MainMenu.soundsTbl.cinematic.nukeSiren
		local nukeRumbling = References_MainMenu.soundsTbl.cinematic.nukeRumbling
		nukeSiren:Play()
		task.wait(3)
		nukeRumbling:Play()
		local timeToFade = 3
		local sirenFade = References_MainMenu.SoundUtil.fadeVolume(nukeSiren, 0, timeToFade)
		sirenFade.Completed:Once(function(a0: Enum.PlaybackState)  
			nukeSiren:Stop()
		end)
		task.wait(0.5)
		References_MainMenu.Frame.BackgroundColor3 = Color3.new(1, 0.415686, 0.078431)
		local fadeToBlack = References_MainMenu.TweenService:Create(References_MainMenu.Frame, TweenInfo.new(5, Enum.EasingStyle.Linear), {BackgroundColor3 = Color3.new()})
		-- local fadeToOpaque = References_MainMenu.TweenService:Create(References_MainMenu.Frame, TweenInfo.new(5, Enum.EasingStyle.Linear), {BackgroundTransparency = 1})
		-- fadeToOpaque:Play()
		fadeToBlack:Play()

		resolve()
	end)
end

function MainMenuManager.resetIfNeeded()
	if not MainMenuManager.isReset then
		MainMenuManager.reset()
	end
end

function MainMenuManager.toggleSlideSidePanels(toggle: boolean, timeToSlide: number)
	ButtonsPanelManager.togglePanel(toggle, timeToSlide)
	RightPanelManager.togglePanel(toggle, timeToSlide)
end

function MainMenuManager.openTitleScreenVersion(timeToOpen: number)
	return Promise.new(function(resolve, reject, onCancel)
		-- registering cancel callback
		onCancel(function()
			-- cleanup
			local nukeSound = References_MainMenu.soundsTbl.cinematic.nukeRumbling
			if nukeSound.IsPlaying then
				local silenceNukeSound = References_MainMenu.SoundUtil.fadeVolume(nukeSound, 0, 0.5)
				silenceNukeSound.Completed:Once(function(a0: Enum.PlaybackState)  
					silenceNukeSound:Stop()
				end)
				
			end
		end)

		--*****setup
		ButtonsPanelManager.toggleButtons(false, 0)
		ButtonsPanelManager.togglePanel(false, 0)
		RightPanelManager.togglePanel(false, 0)

		--*****
		local menuMusic = References_MainMenu.soundsTbl.music.menuMusic
		menuMusic.Volume = 0
		menuMusic:Play()
		References_MainMenu.SoundUtil.fadeVolume(menuMusic, 1, timeToOpen)

		for _, v in References_MainMenu.panels do
			v.BackgroundTransparency = 1
			v.GroupTransparency = 0
		end
		References_MainMenu.CenterPanel.GroupTransparency = 1
		References_MainMenu.TweenService:Create(References_MainMenu.CenterPanel, TweenInfo.new(timeToOpen, Enum.EasingStyle.Linear), {GroupTransparency = 0}):Play()

		task.wait(2)

		ButtonsPanelManager.togglePanel(true, 0.5)
		task.wait(0.5)
		ButtonsPanelManager.toggleButtons(true, 0.5)

		-- print(mainMenuCutscenes.Scene1)
		-- CameraCutsceneManager.PlayCutscene(workspace.CurrentCamera, CameraCutsceneManager.CreateCutsceneCameraPositions(mainMenuCutscenes.Scene1))
		-- 	:andThen(function()
		-- 		print("Cutscene executed successfully")
		-- 	end)
		-- 	:catch(function(err)
		-- 		warn(tostring(err))
		-- 	end)

		resolve()
	end)
end

function MainMenuManager.openGameMenuVersion()

end

function MainMenuManager.closeGameMenu()

end

function MainMenuManager.close(timeToClose: number)
	local menuMusic = References_MainMenu.soundsTbl.music.menuMusic
	if menuMusic.isPlaying then
		References_MainMenu.SoundUtil.fadeVolume(menuMusic, 0, timeToClose)
	end
end

function MainMenuManager.closeTitleScreen()
	ButtonsPanelManager.toggleButtons(false, 0.1)
	MainMenuManager.toggleSlideSidePanels(false, 1)
	local pitch_loadingMusic = Instance.new("PitchShiftSoundEffect")
	pitch_loadingMusic.Octave = 1
	local menuMusic = References_MainMenu.soundsTbl.music.menuMusic
	pitch_loadingMusic.Parent = menuMusic
	local tweenTime = 2
	References_MainMenu.SoundUtil.pitchDown(pitch_loadingMusic, tweenTime)
	local volumeTween = References_MainMenu.SoundUtil.fadeVolume(menuMusic, 0, tweenTime)
	volumeTween.Completed:Wait()
	References_MainMenu.soundsTbl.music.menuMusic:Stop()
	task.wait(0.5)
	References_MainMenu.soundsTbl.cinematic.switchShutOff:Play()
	References_MainMenu.CenterPanel.GroupTransparency = 1
	References_MainMenu.TweenService:Create(References_MainMenu.CenterPanel, TweenInfo.new(0, Enum.EasingStyle.Linear), {GroupTransparency = 1}):Play()
	task.wait(1)
	MainMenuManager.menuIcon:setEnabled(true)

	References_MainMenu.TweenService:Create(References_MainMenu.Frame, TweenInfo.new(2, Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
end


return MainMenuManager