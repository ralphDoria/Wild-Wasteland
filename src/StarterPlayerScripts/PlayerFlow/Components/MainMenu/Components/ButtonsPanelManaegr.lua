local References_MainMenu = require("./References_MainMenu")
local ButtonsPanelManager = {}

local buttonConnections = {}:: {RBXScriptConnection}

function ButtonsPanelManager.connectButtonEvents(clickCallbackTbl: References_MainMenu.MainMenuButtons<(toggle: boolean) -> ()>)

	for buttonName, v in References_MainMenu.buttonsTbl do
		local textButton = v:: TextButton
		-- hover events
		table.insert(
			buttonConnections,
			textButton.MouseEnter:Connect(function(a0: number, a1: number)  
				References_MainMenu.playSound(References_MainMenu.soundsTbl.ui.hover)	
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

function ButtonsPanelManager.togglePanel(toggle: boolean, timeToSlide: number)
	local tweenInfo = TweenInfo.new(timeToSlide, Enum.EasingStyle.Linear)
	References_MainMenu.TweenService:Create(References_MainMenu.ButtonsPanel, tweenInfo, {Position = UDim2.new(if toggle then 0 else -1, 0)}):Play()
end

local defaultButtonTweenTime = 0.5
--[[
	***This function does not manipulate the position of the buttons panel. This animates the buttons according to the toggle parameter and tweenTime passed. 
]]
function ButtonsPanelManager.toggleButtons(toggle: boolean, tweenTime: number)
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

return ButtonsPanelManager