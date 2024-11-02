local organizer = {}
local TweenService = game:GetService("TweenService")

function organizer.init(titleScreenElements, loadingScreenElements, stroke, corner)
    organizer.titleScreenElements = titleScreenElements
    organizer.loadingScreenElements = loadingScreenElements
    organizer.stroke = stroke
    organizer.corner = corner
end

function organizer.hoverEffect(old, new)
    if old ~= nil then
		old.Size = UDim2.new(1, 0, 0, 50)
		old.TextTransparency = 0.3
	end
	if new ~= nil then
		new.Size = UDim2.new(1, 0, 0, 60)
		new.TextTransparency = 0
	end
end

function organizer.selectEffect(guiObject)
	organizer.stroke.Parent = guiObject
	organizer.corner.Parent = guiObject
end

function organizer.togglePage(page, toggle : boolean, time : number)
	local tween
	if toggle then
		tween = TweenService:Create(page, TweenInfo.new(time), {Size = UDim2.fromScale(0.8, 1)})
	else
		tween = TweenService:Create(page, TweenInfo.new(time), {Size = UDim2.fromScale(0.8, 0)})
	end
	tween:Play()
	return tween
end

function organizer.toggleGuiVisibilityIn(arrayElements, toggle : boolean)
	for _, v in arrayElements do
		if v:IsA("GuiObject") then
			v.Visible = toggle
		end
	end
end

function organizer.toggleButtonsInteractable(toggle : boolean)
	for _, button in organizer.titleScreenElements.buttons:GetChildren() do
		if button:IsA("GuiButton") then
			button.Interactable = toggle
		end
	end
end

return organizer