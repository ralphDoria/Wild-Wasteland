-- Services
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

-- DURING TITLE SCREEN, CHARACTER AND ALL IT'S DEPENDENT SYSTEMS WILL BE INITIALIZING IN THE BACKGROUND

local openingTitleScreenPromise
LoadingScreenManager.transitionOut()
MainMenuManager.init(
    function() -- onPlayButtonClicked 
        GuiService.TouchControlsEnabled = true
        player.CameraMode = Enum.CameraMode.LockFirstPerson
        task.defer(function()
            --This has to run deferred so that, from my guess, the RunService camera event has time to take effect and successfully puts the player into first person
            player.CameraMode = Enum.CameraMode.Classic
        end)
        if openingTitleScreenPromise then
            openingTitleScreenPromise:cancel()
        else
            warn("openingTitleScreenPromise is nil")
        end
    end,
    function() -- onTitleScreenFadingOut 
    end
)

MainMenuManager.playNukeScene()
    :catch(function(err)
        warn(tostring(err))
    end)
    :await()
LoadingScreenManager.Destroy()

openingTitleScreenPromise = MainMenuManager.openTitleScreenVersion(5)
openingTitleScreenPromise
    :catch(function(err)
        warn(tostring(err))
    end)