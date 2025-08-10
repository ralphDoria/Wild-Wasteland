local organizer = {}
local TweenService = game:GetService("TweenService")

local buttonsPanel
local logo

organizer.pageStatuses = {
	["CONTROLS"] = false,
	["NOTES"] = false,
	["SETTINGS"] = false,
}

function organizer.init(titleScreenElements, loadingScreenElements, sideScreens, stroke, corner)
    organizer.titleScreenElements = titleScreenElements
	buttonsPanel = titleScreenElements.buttons
	logo = titleScreenElements.logo
	organizer.sideScreens = sideScreens
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

function organizer.toggleButtonsPanel(toggle : boolean, time : number)
	local tween
				--[[ 
				--TOP TO BOTTOM (SIZE)
				if toggle then
					tween = TweenService:Create(organizer.titleScreenElements.buttons, TweenInfo.new(time), {Size = UDim2.fromScale(0.2, 1)})
				else
					tween = TweenService:Create(organizer.titleScreenElements.buttons, TweenInfo.new(time), {Size = UDim2.fromScale(0.2, 0)})
				end
				]]
	--LEFT TO RIGHT (POSITION)
	if toggle then
		tween = TweenService:Create(organizer.titleScreenElements.buttons, TweenInfo.new(time), 
			{Position = UDim2.fromScale(0, 0)})
	else
		tween = TweenService:Create(buttonsPanel, TweenInfo.new(time), 
			{Position = UDim2.fromScale(-(buttonsPanel.Size.X.Scale), 0)})
	end
	tween:Play()
	return tween
end

function organizer.tweenLogoTransparency(value : number, time : number)
	local tween = TweenService:Create(logo, TweenInfo.new(time, Enum.EasingStyle.Bounce, Enum.EasingDirection.InOut), 
		{ImageTransparency = value}
	)
	tween:Play()
	return tween
end

--[[
	Hides/shows a specified page (w/ tween animations). Also tweens logo transparency.
]]
function organizer.togglePage(page, toggle : boolean, time : number)
	local buttonsPanelNotFullyOpened = buttonsPanel.Position ~= UDim2.fromScale(0, 0)
	if buttonsPanelNotFullyOpened then
		print("waiting for buttons panel to fully open")
		organizer.toggleButtonsPanel(true, 0)
	end
	local tween
	local scrollingFrame : ScrollingFrame = page:FindFirstChildWhichIsA("ScrollingFrame")
	if toggle then
		organizer.pageStatuses[page.Name] = true
		organizer.tweenLogoTransparency(0.9, time)
		tween = TweenService:Create(scrollingFrame, TweenInfo.new(time), 
			{Position = UDim2.fromScale(0, 0)})
	else
		organizer.pageStatuses[page.Name] = false
		organizer.tweenLogoTransparency(0, time)
		tween = TweenService:Create(scrollingFrame, TweenInfo.new(time), 
			{Position = UDim2.fromScale(-(scrollingFrame.Size.X.Scale), 0)})
	end
	tween:Play()
	return tween
end

--[[
	Uses organizer.togglePage() to toggle all pages to false, except for the page that is passed. By extension of using togglePage(), 
	this function also tweens the logo transparency.
]]
function organizer.closeAllPagesExcept(page, time)
	for pageName, activated in organizer.pageStatuses do

		if page ~= nil and pageName == page.Name then continue end

		if activated == true then
			organizer.pageStatuses[pageName] = false
			organizer.togglePage(organizer.sideScreens[pageName], false, time)
		end

	end
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