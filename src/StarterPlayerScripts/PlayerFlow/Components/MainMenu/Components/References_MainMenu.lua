local References_MainMenu = {}

-- Services and Player references
local ReplicatedStorage = game:GetService("ReplicatedStorage")
References_MainMenu.TweenService = game:GetService("TweenService")
References_MainMenu.MainMenu = ReplicatedStorage.MainMenu:: ScreenGui 
References_MainMenu.player = game:GetService("Players").LocalPlayer
References_MainMenu.playerGui = References_MainMenu.player.PlayerGui

-- Instance
References_MainMenu.Frame = References_MainMenu.MainMenu.Frame:: Frame
        -- Buttons Panel
References_MainMenu.ButtonsPanel = References_MainMenu.Frame.ButtonsPanelWrapperFrame.ButtonsPanel:: CanvasGroup
export type MainMenuButtons<T> = {
	play: T,
	controls: T,
	settings: T,
	notes: T
}
References_MainMenu.buttonsTbl = {
	play = References_MainMenu.ButtonsPanel.Play,
	controls = References_MainMenu.ButtonsPanel.Controls,
	settings = References_MainMenu.ButtonsPanel.Settings,
	notes = References_MainMenu.ButtonsPanel.Notes
}:: MainMenuButtons<TextButton>
        -- Center Panel
References_MainMenu.CenterPanel = References_MainMenu.Frame.CenterPanelWrapperFrame.CenterPanel:: CanvasGroup
        -- RightPanel
References_MainMenu.RightPanel = References_MainMenu.Frame.RightPanelWrapperFrame.RightPanel:: CanvasGroup
References_MainMenu.panels = {References_MainMenu.ButtonsPanel, References_MainMenu.CenterPanel, References_MainMenu.RightPanel}
export type RightPanelInterfaces<T> = {
    controls: T,
    settings: T,
    notes: T
}
References_MainMenu.rightPanelTbl = {
	controls = References_MainMenu.RightPanel.Controls,
	settings = References_MainMenu.RightPanel.Settings,
	notes = References_MainMenu.RightPanel.Notes
}:: RightPanelInterfaces<CanvasGroup>

-- Sounds
References_MainMenu.SoundsFolder = References_MainMenu.MainMenu.Sounds:: Folder
References_MainMenu.soundsTbl = {
	music = {
		menuMusic = References_MainMenu.SoundsFolder.music:FindFirstChildOfClass("Sound"):: Sound
	},
	ui = {
		click = References_MainMenu.SoundsFolder:FindFirstChild("click", true):: Sound,
		hover = References_MainMenu.SoundsFolder:FindFirstChild("hover", true):: Sound
	},
	cinematic = {
		nukeRumbling = References_MainMenu.SoundsFolder:FindFirstChild("nukeRumbling", true):: Sound,
		nukeSiren = References_MainMenu.SoundsFolder:FindFirstChild("nukeSiren", true):: Sound,
		buzzingLight = References_MainMenu.SoundsFolder:FindFirstChild("buzzingLight", true):: Sound,
		switchShutOff = References_MainMenu.SoundsFolder:FindFirstChild("switchShutOff", true):: Sound,
	}
}

-- Utility Modules
local utility = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility")
References_MainMenu.SoundUtil = require(utility:WaitForChild("SoundUtil"))
References_MainMenu.playSound = require(utility:WaitForChild("PlaySoundUtil"))
References_MainMenu.CameraCutsceneManager = require(ReplicatedStorage.RojoManaged_RS.CameraCutsceneManager)
References_MainMenu.MainMenuCutsceneFolder = workspace.MainMenuCameraPositions
References_MainMenu.mainMenuCutscenes = {
	Scene1 = References_MainMenu.MainMenuCutsceneFolder:WaitForChild("Scene1")
}
-- References_MainMenu.reference_TopBarPlus = ReplicatedStorage.Packages:FindFirstChild("TopBarPlus")
-- References_MainMenu.Icon = require(reference_TopBarPlus:FindFirstChild("Icon"):: any)
References_MainMenu.getHardwareSafeAreaInsets = require(ReplicatedStorage.RojoManaged_RS.Utility.UI.getHardwareSafeAreaInsets)
References_MainMenu.SoundGroupManager = require(ReplicatedStorage.RojoManaged_RS.Utility.Sound.SoundGroupManager)
References_MainMenu.TopBarPlusIcon = require(ReplicatedStorage.Packages.Icon)

return References_MainMenu