local References_MainMenu = require("./Components/References_MainMenu")
local MainMenuManager = {initialied = false, isReset = false}

function MainMenuManager.init()
	References_MainMenu.SoundGroupManager.muteAllExcept(References_MainMenu.SoundGroupManager.soundGroups.music)
	References_MainMenu.SoundGroupManager.soundGroups.master.Volume = 1 -- LoadingScreenManager mutes master volume
	MainMenuManager.reset()
	References_MainMenu.MainMenu.Parent = References_MainMenu.playerGui
	MainMenuManager.connectButtonEvents()

	MainMenuManager.initialized = true
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
	MainMenuManager.toggleShowButtons(false, 0)
	References_MainMenu.MainMenu.Enabled = true

	MainMenuManager.isReset = true
end

function MainMenuManager.playNukeScene()
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
end

function MainMenuManager.resetIfNeeded()
	if not MainMenuManager.isReset then
		MainMenuManager.reset()
	end
end

--[[
	***This function does not manipulate the position of the buttons panel. This animates the buttons according to the toggle parameter and tweenTime passed. 
]]
function MainMenuManager.toggleShowButtons(toggle: boolean, tweenTime: number)
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
	local leftSafeAreaInset: number
	if toggle then
		local _: any
		leftSafeAreaInset , _ = References_MainMenu.getHardwareSafeAreaInsets()
		if leftSafeAreaInset == 0 then
			leftSafeAreaInset = 10
		end
	end

	local function Map<T, K>(tbl: {T}, mapping: (value: T) -> K)
		local newTbl = table.create(#tbl)

		for i, v in tbl do
			newTbl[i] = mapping(v)
		end

		return newTbl
	end

	local buttonTweens: References_MainMenu.MainMenuButtons<{Tween}> = Map(References_MainMenu.buttonsTbl, function(button: TextButton)
		button.Interactable = toggle
		local paddingTween = References_MainMenu.TweenService:Create(button:FindFirstChildOfClass("UIPadding"), tweenInfo, {PaddingLeft = UDim.new(0, if leftSafeAreaInset then leftSafeAreaInset else 0)})
		local textTransparencyTween = References_MainMenu.TweenService:Create(button, tweenInfo, {TextTransparency = if toggle then 0 else 1})
		return {paddingTween, textTransparencyTween}
	end)
	task.spawn(function()
		local function playAllTweens(tweenTbl: {Tween})
			for buttonName, v in tweenTbl do 
				v:Play()
			end
		end
		

		local intervalTime = 0.1
		playAllTweens(buttonTweens.play)
		task.wait(intervalTime)
		playAllTweens(buttonTweens.controls)
		task.wait(intervalTime)
		playAllTweens(buttonTweens.settings)
		task.wait(intervalTime)
		playAllTweens(buttonTweens.notes)
	end)
end

function MainMenuManager.toggleSlideButtonsPanel(toggle: boolean, timeToSlide: number)
	local tweenInfo = TweenInfo.new(timeToSlide, Enum.EasingStyle.Linear)
	References_MainMenu.TweenService:Create(References_MainMenu.ButtonsPanel, tweenInfo, {Position = UDim2.new(if toggle then 0 else -1, 0)}):Play()
end

function MainMenuManager.toggleSlideRightPanel(toggle: boolean, timeToSlide: number)
	local tweenInfo = TweenInfo.new(timeToSlide, Enum.EasingStyle.Linear)
	References_MainMenu.TweenService:Create(References_MainMenu.RightPanel, tweenInfo, {Position = UDim2.new(if toggle then 0 else 1, 0)}):Play()
end

function MainMenuManager.toggleSlideSidePanels(toggle: boolean, timeToSlide: number)
	MainMenuManager.toggleSlideButtonsPanel(toggle, timeToSlide)
	MainMenuManager.toggleSlideRightPanel(toggle, timeToSlide)
end

function MainMenuManager.openTitleScreenVersion(timeToOpen: number)
	--*****setup
	MainMenuManager.toggleShowButtons(false, 0)
	MainMenuManager.toggleSlideButtonsPanel(false, 0)
	MainMenuManager.toggleSlideRightPanel(false, 0)

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

	MainMenuManager.toggleSlideButtonsPanel(true, 0.5)
	task.wait(0.5)
	MainMenuManager.toggleShowButtons(true, 0.5)

	-- print(mainMenuCutscenes.Scene1)
	-- CameraCutsceneManager.PlayCutscene(workspace.CurrentCamera, CameraCutsceneManager.CreateCutsceneCameraPositions(mainMenuCutscenes.Scene1))
	-- 	:andThen(function()
	-- 		print("Cutscene executed successfully")
	-- 	end)
	-- 	:catch(function(err)
	-- 		warn(tostring(err))
	-- 	end)
end

function MainMenuManager.openGameMenuVersion()

end

function MainMenuManager.close(timeToClose: number)
	local menuMusic = References_MainMenu.soundsTbl.music.menuMusic
	if menuMusic.isPlaying then
		References_MainMenu.SoundUtil.fadeVolume(menuMusic, 0, timeToClose)
	end
end

MainMenuManager.buttonConnections = {}:: {RBXScriptConnection}

function MainMenuManager.closeTitleScreen()
	MainMenuManager.toggleShowButtons(false, 0.1)
	MainMenuManager.toggleSlideSidePanels(false, 1)
	local pitch_loadingMusic = Instance.new("PitchShiftSoundEffect")
	pitch_loadingMusic.Octave = 1
	local menuMusic = References_MainMenu.soundsTbl.music.menuMusic
	pitch_loadingMusic.Parent = menuMusic
	local tweenTime = 1
	References_MainMenu.SoundUtil.pitchDown(pitch_loadingMusic, tweenTime)
	local volumeTween = References_MainMenu.SoundUtil.fadeVolume(menuMusic, 0, tweenTime)
	volumeTween.Completed:Wait()
	References_MainMenu.soundsTbl.music.menuMusic:Stop()
	task.wait(0.5)
	References_MainMenu.soundsTbl.cinematic.switchShutOff:Play()
	References_MainMenu.CenterPanel.GroupTransparency = 1
	task.wait(1)

	References_MainMenu.TweenService:Create(References_MainMenu.Frame, TweenInfo.new(2, Enum.EasingStyle.Linear), {BackgroundTransparency = 1}):Play()
end


function MainMenuManager.connectButtonEvents()

	local clickCallbackTbl: References_MainMenu.MainMenuButtons<(toggle: boolean) -> ()> = {
		play = function(toggle: boolean)
			print("Play button clicked")	
			MainMenuManager.closeTitleScreen()			
		end,
		controls = function(toggle: boolean)
			print("Controls button clicked")	
		end,
		settings = function(toggle: boolean)
			print("Settings button clicked")	
		end,
		notes = function(toggle: boolean)
			print("Notes button clicked")	
		end
	}

	for buttonName, v in References_MainMenu.buttonsTbl do
		local textButton = v:: TextButton
		-- hover events
		table.insert(
			MainMenuManager.buttonConnections,
			textButton.MouseEnter:Connect(function(a0: number, a1: number)  
				References_MainMenu.playSound(References_MainMenu.soundsTbl.ui.hover)	
				textButton.Size = UDim2.fromOffset(0, 70)
			end)
		)
		table.insert(
			MainMenuManager.buttonConnections,
			textButton.MouseLeave:Connect(function(a0: number, a1: number)  
				textButton.Size = UDim2.fromOffset(0, 50)
			end)
		)

		--click events
		table.insert(
			MainMenuManager.buttonConnections,
			textButton.MouseButton1Click:Connect(function(...: any)  
				References_MainMenu.playSound(References_MainMenu.soundsTbl.ui.click)	
				if textButton.FontFace.Style == Enum.FontStyle.Normal then
					textButton.FontFace.Style = Enum.FontStyle.Italic
					clickCallbackTbl[buttonName](true)
				else
					textButton.FontFace.Style = Enum.FontStyle.Normal
					clickCallbackTbl[buttonName](false)
				end
			end)
		)
	end
	
end

return MainMenuManager