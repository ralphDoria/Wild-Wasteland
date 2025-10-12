local References_MainMenu = require("./References_MainMenu")
local ButtonsPanelManager = {}

local buttonConnections = {}:: {RBXScriptConnection}
local buttonState: References_MainMenu.MainMenuButtons<boolean> = {
	play = false,
	controls = false,
	settings = false,
	notes = false
}



local hoverSelectSize = UDim2.fromOffset(0, 70)
local regularSize = UDim2.fromOffset(0, 50)
function ButtonsPanelManager.connectButtonEvents(clickCallbackTbl: References_MainMenu.MainMenuButtons<(toggle: boolean) -> ()>)

	for buttonName, textButton: TextButton in References_MainMenu.buttonsTbl do
		-- hover events
		table.insert(
			buttonConnections,
			textButton.MouseEnter:Connect(function(a0: number, a1: number)  
				References_MainMenu.playSound(References_MainMenu.soundsTbl.ui.hover)	
				local isEnabled = buttonState[buttonName]
				if not isEnabled then
					textButton.Size = hoverSelectSize
				end
			end)
		)
		table.insert(
			buttonConnections,
			textButton.MouseLeave:Connect(function(a0: number, a1: number)  
				local isEnabled = buttonState[buttonName]
				if not isEnabled then
					textButton.Size = regularSize
				end
			end)
		)

		--click events
		table.insert(
			buttonConnections,
			textButton.MouseButton1Click:Connect(function(...: any)  
				References_MainMenu.playSound(References_MainMenu.soundsTbl.ui.click)	
				local isEnabled = buttonState[buttonName]
				local newEnabledState = not isEnabled
				clickCallbackTbl[buttonName](newEnabledState)
				textButton.Size = if newEnabledState then hoverSelectSize else regularSize
				for name, v in References_MainMenu.buttonsTbl do
					if v == textButton then continue end
					v.Size = regularSize
					buttonState[name] = false
				end
				buttonState[buttonName] = newEnabledState
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