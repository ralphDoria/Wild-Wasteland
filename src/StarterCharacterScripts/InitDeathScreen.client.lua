-- This script runs in StarterPlayerScripts and the ScreenGui does not reset on spawn
-- !strict

-- Services and General Player References
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = char:WaitForChild("Humanoid")
local playerGui = player.PlayerGui

-- Gui Instances
local DeathScreen = playerGui:WaitForChild("DeathScreen"):: ScreenGui
local Frame = DeathScreen:WaitForChild("Frame"):: Frame
    --Death Text
local DeathTextLabel = Frame.DeathTextLabel:: TextLabel
    -- Button references
local ButtonsPanel = Frame.ButtonsPanel:: Frame
type DeathScreenButtons<T> = {
	respawn: T,
	titleScreen: T
}
local buttonsTbl = {
    respawn = ButtonsPanel.Respawn,
    titleScreen = ButtonsPanel.TitleScreen
}:: DeathScreenButtons<TextButton>

-- Sound Instances
local gustOfWind: Sound = DeathScreen["Fallout Wasteland Wind Gust"]
local MainMenu = playerGui:WaitForChild("MainMenu"):: ScreenGui
local MainMenuSoundsFolder = MainMenu.Sounds:: Folder
local uiSounds = {
    click = MainMenuSoundsFolder:FindFirstChild("click", true):: Sound,
    hover = MainMenuSoundsFolder:FindFirstChild("hover", true):: Sound
}

-- Utility
local utility = ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility")
local SoundUtil = require(utility:WaitForChild("SoundUtil"))
local playSound = require(utility:WaitForChild("PlaySoundUtil"))
local TransitionBlackScreenManager = require(ReplicatedStorage.RojoManaged_RS.Utility.UI.TransitionBlackScreenManager)

local VitalsSystem_Storage = ReplicatedStorage:FindFirstChild("VitalsSystem_Storage", true)
local remotes: {[string]: RemoteEvent} = {
    RespawnPlayerCharacter = VitalsSystem_Storage:FindFirstChild("RespawnPlayerCharacter", true)
}

local ButtonsManager = {}
local buttonConnections = {}
function ButtonsManager.connectButtonEvents(clickCallbackTbl: DeathScreenButtons<(toggle: boolean) -> ()>)

	for buttonName, v in buttonsTbl do
		local textButton = v:: TextButton
		-- hover events
		table.insert(
			buttonConnections,
			textButton.MouseEnter:Connect(function(a0: number, a1: number)  
				playSound(uiSounds.hover)	
				textButton.Size = UDim2.fromOffset(0, 70)
			end)
		)
		table.insert(

			buttonConnections,
			textButton.MouseLeave:Connect(function(a0: number, a1: number)  
				textButton.Size = UDim2.fromOffset(0, 50)
			end)
		)


		--click events
		table.insert(
			buttonConnections,
			textButton.MouseButton1Click:Connect(function(...: any)  
				playSound(uiSounds.click)	
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

function ButtonsManager.toggleButtons(toggle: boolean, tweenTime: number, toggleYield: boolean)
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
	-- local leftSafeAreaInset: number
	-- if toggle then
	-- 	local _: any
	-- 	leftSafeAreaInset , _ = References_MainMenu.getHardwareSafeAreaInsets()
	-- 	if leftSafeAreaInset == 0 then
	-- 		leftSafeAreaInset = 10
	-- 	end
	-- end

	local function Map<T, K>(tbl: {T}, mapping: (value: T) -> K)
		local newTbl = table.create(#tbl)

		for i, v in tbl do
			newTbl[i] = mapping(v)
		end

		return newTbl
	end

	local buttonTweens: DeathScreenButtons<{Tween}> = Map(buttonsTbl, function(button: TextButton)
		button.Interactable = toggle
		local paddingTween = TweenService:Create(button:FindFirstChildOfClass("UIPadding"), tweenInfo, {PaddingLeft = UDim.new(0, if toggle then 50 else 0)}) -- Don't have to worry about hardware inset here because buttons panel doesn't slide in like it does for title screen
		local textTransparencyTween = TweenService:Create(button, tweenInfo, {TextTransparency = if toggle then 0 else 1})
		return {paddingTween, textTransparencyTween}
	end)

    local function startTweening()
		local function playAllTweens(tweenTbl: {Tween})
			for buttonName, v in tweenTbl do 
				v:Play()
			end
		end
		

		local intervalTime = 0.5
		playAllTweens(buttonTweens.respawn)
		task.wait(intervalTime)
		playAllTweens(buttonTweens.titleScreen)
        task.wait(tweenTime)
    end
    
    if toggleYield then
        startTweening()
    else
        task.spawn(function()
            startTweening()
        end)
    end
end

local function toggleTextAndButtons(toggle: boolean, time: number, toggleYield: boolean)
    TweenService:Create(DeathTextLabel, TweenInfo.new(time, Enum.EasingStyle.Linear), {TextTransparency = if toggle then 0 else 1}):Play()
    ButtonsManager.toggleButtons(toggle, time, toggleYield)
end

local function init()
    print("Initializing Death Screen")

    local function setUp()
        Frame.BackgroundTransparency = 1
        for _, v in buttonsTbl do
            v.TextTransparency = 1
        end
        toggleTextAndButtons(false, 0, false)
        DeathScreen.Enabled = true
    end
    setUp()
    
    humanoid.Died:Once(function()  
        ButtonsManager.connectButtonEvents({
            respawn = function(toggle: boolean)
                local fadeOutTime = 3
                toggleTextAndButtons(false, fadeOutTime, true)
                TransitionBlackScreenManager.fadeIn(0)

                remotes.RespawnPlayerCharacter:FireServer() -- remember that this gui will be destroyed when player respawns
            end,
            titleScreen = function(toggle: boolean)
                print("not ready yet")
            end,
        })

        local blackScreenFadeInTime = 3
        local waitInDarknessTime = 1
        local fadeInButtonsAndDeathTextTime = 3

        local fadeInBlackScreen = TweenService:Create(Frame, TweenInfo.new(blackScreenFadeInTime, Enum.EasingStyle.Linear), {BackgroundTransparency = 0}):: Tween
        fadeInBlackScreen:Play()
        fadeInBlackScreen.Completed:Wait()
        task.wait(waitInDarknessTime)
        toggleTextAndButtons(true, fadeInButtonsAndDeathTextTime, false)
    end)
end

init()