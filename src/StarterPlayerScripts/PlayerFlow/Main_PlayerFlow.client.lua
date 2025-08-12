-- Services
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

-- Utility
local Promise = require(ReplicatedStorage.Packages.Promise)

-- Character Dependent Systems
local InventorySystem = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Main_InventorySystem)
local initCharacterStatsManager = require(ReplicatedStorage.RojoManaged_RS.CharacterStatsGuiSystem_ScriptStorage.initCharacterStatsManager)
local SpawnAndDeathManager = require(ReplicatedStorage.RojoManaged_RS.SpawnAndDeathSystem_ScriptStorage.SpawnAndDeathManager)

local LoadingScreenManager = require(ReplicatedFirst.RojoManaged_RF.LoadingScreenScripts.LoadingScreenManager)
local MainMenuManager = require("./Components/MainMenu/MainMenuManager")
-- technically, if LocalScripts not parented to ReplicatedFirst always run after the game has loaded, then it should be safe to not use WaitForChild, but just to be doubly safe
local LoadingScreen = playerGui:WaitForChild("LoadingScreen") 

if not LoadingScreen:GetAttribute("PreloadingFinished") then
    LoadingScreen:GetAttributeChangedSignal("PreloadingFinished"):Wait()
end

--*****Initialize character dependent systems
local function initializeCharacterDependentSystems(char: Model)
    char:SetAttribute("Initialized", false)

    -- TODO: MAKE SURE ALL THESE SYSTEMS CLEAN UP AFTER THEMSELVES WHEN THE CHARACTER DIES
    warn("INITIALIZING CHARACTER DEPENDENT SYSTEMS")
    local humanoid = char:WaitForChild("Humanoid")
    humanoid.Died:Once(function()
        --init death screen
    end)
    Promise.promisify(InventorySystem.init)()
        :catch(function(err)
            warn(tostring(err))
        end)
    Promise.promisify(initCharacterStatsManager)()
        :catch(function(err)
            warn(tostring(err))
        end)
    -- ActionManager
    -- Character Movement

    char:SetAttribute("Initialized", true)
end
local character: Model? = player.Character
if character then
    initializeCharacterDependentSystems(character)    
end
player.CharacterAdded:Connect(function(thisCharacter: Model)  
    initializeCharacterDependentSystems(thisCharacter)    
end)

local openingTitleScreenPromise
LoadingScreenManager.transitionOut()
MainMenuManager.init(
    function()  
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
    function()  
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