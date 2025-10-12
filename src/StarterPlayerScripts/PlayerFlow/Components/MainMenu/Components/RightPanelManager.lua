local References_MainMenu = require("./References_MainMenu")

export type RightPanelState = "Settings" | "Notes" | "Controls" | "None"
local state: RightPanelState = "None"
local RightPanelManager = {}

function RightPanelManager.reset()
	for _, subpanel: CanvasGroup in References_MainMenu.rightPanelTbl do
		subpanel.GroupTransparency = 1
		subpanel.Position = UDim2.fromScale(0.5, 0)
	end
end
RightPanelManager.reset()

function RightPanelManager.setState(newState: RightPanelState)
	state = if newState == state then "None" else newState
	print(state)

	-- transition out other screens
	local ti = TweenInfo.new(0.5)
	for _, subpanel: CanvasGroup in References_MainMenu.rightPanelTbl do
		-- fade to invisible & slide off to the right
		References_MainMenu.TweenService:Create(subpanel, ti, {GroupTransparency = 1}):Play()
		References_MainMenu.TweenService:Create(subpanel, ti, {Position = UDim2.fromScale(0.5, 0)}):Play()
	end

	-- transition in corresponding screen according to state
	local targetPanel  = References_MainMenu.rightPanelTbl[state:lower()]
	if targetPanel then
		References_MainMenu.TweenService:Create(targetPanel, ti, {GroupTransparency = 0}):Play()
		References_MainMenu.TweenService:Create(targetPanel, ti, {Position = UDim2.fromScale(0, 0)}):Play()
	else
		if state ~= "None" then
			warn(`State is invalid: {state:lower()}`)
		end
	end
end

function RightPanelManager.togglePanel(toggle: boolean, timeToSlide: number)
	local tweenInfo = TweenInfo.new(timeToSlide, Enum.EasingStyle.Linear)
	References_MainMenu.TweenService:Create(References_MainMenu.RightPanel, tweenInfo, {Position = UDim2.new(if toggle then 0 else 1, 0)}):Play()
end

return RightPanelManager