local ReplicatedFirst = game:GetService("ReplicatedFirst")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local LoadingScreenManager = require(ReplicatedFirst.RojoManaged_RF.LoadingScreenScripts.LoadingScreenManager)
local MainMenuManager = require("./Components/MainMenu/MainMenuManager")
-- technically, if LocalScripts not parented to ReplicatedFirst always run after the game has loaded, then it should be safe to not use WaitForChild, but just to be doubly safe
local LoadingScreen = playerGui:WaitForChild("LoadingScreen") 

if not LoadingScreen:GetAttribute("PreloadingFinished") then
    LoadingScreen:GetAttributeChangedSignal("PreloadingFinished"):Wait()
end

LoadingScreenManager.transitionOut()
MainMenuManager.init()
MainMenuManager.playNukeScene()
LoadingScreenManager.Destroy()
MainMenuManager.openTitleScreenVersion(5)