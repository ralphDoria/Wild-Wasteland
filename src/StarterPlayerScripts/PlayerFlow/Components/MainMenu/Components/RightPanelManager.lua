local References_MainMenu = require("./References_MainMenu")
local RightPanelManager = {}

function RightPanelManager.togglePanel(toggle: boolean, timeToSlide: number)
	local tweenInfo = TweenInfo.new(timeToSlide, Enum.EasingStyle.Linear)
	References_MainMenu.TweenService:Create(References_MainMenu.RightPanel, tweenInfo, {Position = UDim2.new(if toggle then 0 else 1, 0)}):Play()
end

return RightPanelManager