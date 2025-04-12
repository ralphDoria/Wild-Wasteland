local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local InputCategorizer = require("./Components/InputCategorizer")
local InputMetadata = require("./Components/InputMetadata")
local TouchDisplayerManager = require("./Components/TouchDisplayManager")
local CircularProgressBarManager = require("../Utility/CircularProgressBarManager")

local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")
local actionGui = playerGui:WaitForChild("ActionGui2")
local instances = actionGui:FindFirstChild("Instances") :: any
local nonTouchDisplay = actionGui.NonTouchDisplay


local HORIZONTAL_PADDING = 40
local VERTICAL_PADDING = 70

export type GetCallbacks = () -> (()->(), ()->(), () -> ())

type binding = {
	connections: {RBXScriptConnection},
	keyboardAndMouseInput: Enum.KeyCode | Enum.UserInputType,
	gamepadInput: Enum.KeyCode | Enum.UserInputType,
	frame: Frame,
	touchButton: ImageButton,
	progressBarConnection: RBXScriptConnection?,
	onActivated: () -> (),
	onDeactivated: () -> (),
	onUnbind: () -> (),
	startCooldown: () -> (),
	onCooldown: boolean,
	toggleData: boolean?,
	toggleGuiDisplays: (boolean) -> (),
	enabled: boolean
}

local ActionManager = {
	InputCategory = InputCategorizer.InputCategory,
	_initialized = false,
	_bindings = {} :: { [string]: binding },
}

function ActionManager.bindAction(
	actionName: string,
	getCallbacks: GetCallbacks,
	keyboardAndMouseInput: Enum.KeyCode | Enum.UserInputType,
	gamepadInput: Enum.KeyCode | Enum.UserInputType,
	displayOrder: number,
	initialToggleData: boolean?,
    cooldownTime: number?,
	touchButtonImageId: string
)
	-- Make sure action binds aren't overwritten
	if ActionManager._bindings[actionName] then
		warn(string.format("'%s' is already bound!", actionName))
		return
	end

	local binding = {
		connections = {},
		keyboardAndMouseInput = keyboardAndMouseInput,
		gamepadInput = gamepadInput,
		toggleData = initialToggleData,
		enabled = true
	}

	-- Create a new UI element
	local actionFrame = instances.ActionFrame:Clone()
	actionFrame.ContentFrame.ActionLabel.Text = actionName
	actionFrame.LayoutOrder = 999 - displayOrder
	actionFrame.Parent = nonTouchDisplay:FindFirstChild("ListFrame")

	binding.frame = actionFrame
	ActionManager._updateInputDisplay(binding, InputCategorizer.getLastInputCategory())

	-- Create TouchButton
	binding.touchButton = TouchDisplayerManager.CreateTouchButton(binding, displayOrder, binding.toggleData, cooldownTime, touchButtonImageId)

	-- Initializing progress bar
	binding.onCooldown = false
	if cooldownTime then
		table.insert(
			binding.connections,
			CircularProgressBarManager.CreateProgressBar(actionFrame.ContentFrame.InputFrame, Color3.new(1, 1, 1))
		)

		-- Initializing fadeOutTweens and fadeInTweens
		local tweenInfo = TweenInfo.new(0.2)
		local inputFrame: CanvasGroup = binding.frame.ContentFrame.InputFrame
		local inputFrameUiStroke = inputFrame:FindFirstChildOfClass("UIStroke")::UIStroke
		local actionLabel: TextLabel = binding.frame.ContentFrame.ActionLabel
		local actionLabelUiStroke = actionLabel:FindFirstChildOfClass("UIStroke")::UIStroke
		local fadeInTweens = {
			-- TouchDisplay
			TweenService:Create(binding.touchButton, tweenInfo, {ImageTransparency = binding.touchButton.ImageTransparency}),
			-- NonTouchDisplay
			TweenService:Create(inputFrame, tweenInfo, {GroupTransparency = inputFrame.GroupTransparency}),
			TweenService:Create(inputFrameUiStroke, tweenInfo, {Transparency = inputFrameUiStroke.Transparency}),
			TweenService:Create(actionLabel, tweenInfo, {BackgroundTransparency = actionLabel.BackgroundTransparency}),
			TweenService:Create(actionLabel, tweenInfo, {TextTransparency = actionLabel.TextTransparency}),
			TweenService:Create(actionLabelUiStroke, tweenInfo, {Transparency = actionLabelUiStroke.Transparency})
		}
		local fadedValue = 0.5
		local fadeOutTweens = {
			-- TouchDisplay
			TweenService:Create(binding.touchButton, tweenInfo, {ImageTransparency = fadedValue}),
			-- NonTouchDisplay
			TweenService:Create(inputFrame, tweenInfo, {GroupTransparency = fadedValue}),
			TweenService:Create(inputFrameUiStroke, tweenInfo, {Transparency = fadedValue}),
			TweenService:Create(actionLabel, tweenInfo, {BackgroundTransparency = fadedValue}),
			TweenService:Create(actionLabel, tweenInfo, {TextTransparency = fadedValue}),
			TweenService:Create(actionLabelUiStroke, tweenInfo, {Transparency = fadedValue})
		}

		function binding.startCooldown()
			local actionFrameProgressBar = binding.frame:FindFirstChild("ProgressBar", true)
			local touchButtonProgressBar = binding.touchButton:FindFirstChild("ProgressBar")
			CircularProgressBarManager.PlayProgressBar(actionFrameProgressBar, "Drain", cooldownTime)
			local completed: RBXScriptSignal = CircularProgressBarManager.PlayProgressBar(touchButtonProgressBar, "Drain", cooldownTime)
			binding.onCooldown = true
			for _, v in fadeOutTweens do
				v:Play()
			end
			completed:Once(function()
				binding.onCooldown = false
				for _, v in fadeInTweens do
					v:Play()
				end
			end)
		end
	end

	function binding.toggleGuiDisplays(thisToggle: boolean)
		TouchDisplayerManager.toggleButtonImage(binding.touchButton, thisToggle)
		if thisToggle then
			actionFrame.ContentFrame.ActionLabel.BackgroundColor3 = Color3.new(1, 1, 1)
			actionFrame.ContentFrame.ActionLabel.TextColor3 = Color3.new(0, 0, 0)
		else
			actionFrame.ContentFrame.ActionLabel.BackgroundColor3 = Color3.fromRGB(103, 69, 0)
			actionFrame.ContentFrame.ActionLabel.TextColor3 = Color3.new(1, 1, 1)
		end
	end

	-- Create a wrapper for the callback function so the UI can be updated in sync with the action
	binding.onActivated, binding.onDeactivated, binding.onUnbind = getCallbacks()
	local callbackWrapper = function(...)
		local action, inputState = ...
		if action == actionName then

			if not binding.enabled then return end

			if binding.toggleData == nil then
				if inputState == Enum.UserInputState.Begin then
					if cooldownTime then
						if binding.onCooldown then
							warn("still on cooldown")
							return
						else
							binding.startCooldown()
						end
					end
					binding.toggleGuiDisplays(true)
					binding.onActivated()
				elseif inputState == Enum.UserInputState.End then
					binding.toggleGuiDisplays(false)
					binding.onDeactivated()
				end
			else
				--toggle button is active
				if inputState == Enum.UserInputState.Begin then
					if binding.toggleData then
						binding.toggleData = false
						binding.onDeactivated()
						binding.toggleGuiDisplays(false)
					else
						if cooldownTime then
							if binding.onCooldown then
								warn("still on cooldown")
								return
							else
								binding.startCooldown()
							end
						end
						binding.toggleData = true
						binding.onActivated()
						binding.toggleGuiDisplays(true)
					end
				end
			end

		end
	end

	-- Touch button connections
	table.insert(
		binding.connections,
		binding.touchButton.InputBegan:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				callbackWrapper(actionName, Enum.UserInputState.Begin, inputObject)
			end
		end)
	)
	table.insert(
		binding.connections,
		binding.touchButton.InputEnded:Connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				callbackWrapper(actionName, Enum.UserInputState.End, inputObject)
			end
		end)
	)

	-- Bind the action using ContextActionService
	ContextActionService:BindAction(actionName, callbackWrapper, false, keyboardAndMouseInput, gamepadInput)
	-- Save the binding
	ActionManager._bindings[actionName] = binding
end

function ActionManager.unbindAction(actionName: string)
	local binding = ActionManager._bindings[actionName]
	if binding then
		-- Disconnect all connections for the binding
		for _, connection in binding.connections do
			connection:Disconnect()
		end
		-- Destroy the UI element for the binding
		binding.frame:Destroy()
		binding.touchButton:Destroy()
		binding.fadeInTweens = nil
		binding.fadeOutTweens = nil
		ActionManager._bindings[actionName] = nil
		-- Unbind the action from ContextActionService
		ContextActionService:UnbindAction(actionName)
		binding.onUnbind() 
	end
end

function ActionManager.toggleEnabled(actionName: string, enabledState: boolean)
	local binding = ActionManager._bindings[actionName]
	if binding.enabled ~= enabledState then
		warn("toggling enabled for", actionName, "to", enabledState)
		binding.enabled = enabledState
	end
end

function ActionManager.forceToggle(actionName: string, targetToggle: boolean?)
	local binding = ActionManager._bindings[actionName]

	if not binding.enabled then return end

	local currentToggle = binding.toggleData
	if currentToggle == nil then
		if targetToggle then
			if binding.startCooldown then
				if binding.onCooldown then
					warn("still on cooldown")
					return
				else
					binding.startCooldown()
				end
			end
			binding.toggleGuiDisplays(true)
			binding.onActivated()
		else
			binding.toggleGuiDisplays(false)
			binding.onDeactivated()
		end
	else
		--toggle button is active
		if currentToggle == targetToggle then return end

		if not targetToggle then
			binding.toggleData = false
			binding.onDeactivated()
			binding.toggleGuiDisplays(false)
		else
			if binding.startCooldown then
				if binding.onCooldown then
					warn("still on cooldown")
					return
				else
					binding.startCooldown()
				end
			end
			binding.toggleData = true
			binding.onActivated()
			binding.toggleGuiDisplays(true)
		end
	end
end

function ActionManager._updateInputDisplay(binding, inputCategory)
	-- Remove old button display
	local oldButtonDisplay = binding.frame.ContentFrame.InputFrame:FindFirstChild("ButtonDisplayFrame")
	if oldButtonDisplay then
		oldButtonDisplay:Destroy()
	end

	if inputCategory == InputCategorizer.InputCategory.Touch then
		nonTouchDisplay.Visible = false
		TouchDisplayerManager.getTouchDisplay().Visible = true
	else
		nonTouchDisplay.Visible = true
		TouchDisplayerManager.getTouchDisplay().Visible = false
		-- Get a new button display
		local buttonDisplay: Instance
		if inputCategory == InputCategorizer.InputCategory.KeyboardAndMouse then
			buttonDisplay = ActionManager._getButtonDisplayForInput(binding.keyboardAndMouseInput)
		elseif inputCategory == InputCategorizer.InputCategory.Gamepad then
			buttonDisplay = ActionManager._getButtonDisplayForInput(binding.gamepadInput)
		end
		buttonDisplay.Parent = binding.frame.ContentFrame.InputFrame
	end
end

-- Create a new button display frame based on the provided KeyCode or UserInputType
function ActionManager._getButtonDisplayForInput(input: Enum.KeyCode | Enum.UserInputType)
	local buttonDisplay = instances.ButtonDisplayFrame:Clone()
	local gamepadImage
	if input.EnumType == Enum.KeyCode then
		gamepadImage = UserInputService:GetImageForKeyCode(input :: Enum.KeyCode)
	end

	if input == Enum.UserInputType.Touch then
		local touchIcon = instances.TouchImageLabel:Clone()
		touchIcon.Parent = buttonDisplay
	elseif gamepadImage and gamepadImage ~= "" then
		local gamepadIcon = instances.GamepadImageLabel:Clone()
		gamepadIcon.Image = gamepadImage
		gamepadIcon.Parent = buttonDisplay
	elseif InputMetadata.MouseButtonImage[input] then
		local mouseIcon = instances.MouseImageLabel:Clone()
		mouseIcon.Image = InputMetadata.MouseButtonImage[input]
		mouseIcon.Parent = buttonDisplay
	else
		local border = instances.KeyboardBorderImage:Clone()
		border.Parent = buttonDisplay

		-- The following logic was taken and modified from the ProximityPrompt CoreScript
		-- UserInputService:GetStringForKeyCode() is used to display the correct input key when
		-- dealing with non-QWERTY keyboards
		local buttonTextString = UserInputService:GetStringForKeyCode(input :: Enum.KeyCode)

		local buttonTextImage = InputMetadata.KeyboardButtonImage[input]
		if not buttonTextImage then
			buttonTextImage = InputMetadata.KeyboardButtonIconMapping[buttonTextString]
		end

		if not buttonTextImage then
			local keyCodeMappedText = InputMetadata.KeyCodeToTextMapping[input :: Enum.KeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			local keyboardIcon = instances.KeyboardImageLabel:Clone()
			keyboardIcon.Image = buttonTextImage
			keyboardIcon.Parent = buttonDisplay
		elseif buttonTextString and buttonTextString ~= "" then
			local keyboardText = instances.KeyboardTextLabel:Clone()
			keyboardText.Text = buttonTextString
			keyboardText.TextSize = InputMetadata.KeyCodeToFontSize[input :: Enum.KeyCode]
				or InputMetadata.DefaultFontSize
			keyboardText.Parent = buttonDisplay
		end
	end

	return buttonDisplay
end

-- Return an InputCategory based on the UserInputType
function ActionManager._getCategoryOfInputType(inputType: Enum.UserInputType)
	if string.find(inputType.Name, "Gamepad") then
		return InputCategorizer.InputCategory.Gamepad
	elseif inputType == Enum.UserInputType.Keyboard or string.find(inputType.Name, "Mouse") then
		return InputCategorizer.InputCategory.KeyboardAndMouse
	elseif inputType == Enum.UserInputType.Touch then
		return InputCategorizer.InputCategory.Touch
	else
		return InputCategorizer.InputCategory.Unknown
	end
end

-- Return a default input category based on the current peripherals
function ActionManager._getDefaultInputCategory()
	if UserInputService.KeyboardEnabled and UserInputService.MouseEnabled then
		return InputCategorizer.InputCategory.KeyboardAndMouse
	elseif UserInputService.TouchEnabled then
		return InputCategorizer.InputCategory.Touch
	elseif UserInputService.GamepadEnabled then
		return InputCategorizer.InputCategory.Gamepad
	else
		return InputCategorizer.InputCategory.Unknown
	end
end

-- Update the position and scale of the actions list
function ActionManager._updatePositionAndScale()
	local touchControlsEnabled = playerGui:FindFirstChild("TouchGui") ~= nil
	-- This is the same calculation used by the TouchGui for sizing the jump button
	local minScreenSize = math.min(actionGui.AbsoluteSize.X, actionGui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < 500 -- This may be implemented if ToolGuiManager with the ToolSystem implements it.

	local verticalPadding = VERTICAL_PADDING
	if touchControlsEnabled and InputCategorizer.getLastInputCategory() == InputCategorizer.InputCategory.Touch then
		TouchDisplayerManager.updatePositionAndScale()
	else
		-- Offset the vertical padding to account for the ToolGui
		-- Note that the ToolGui will be in the bottom right corner when NonTouchDisplay is visible.
		verticalPadding += 10 + 10
		-- If the screen is considered 'small', scale the action list down
		nonTouchDisplay.ListFrame.UIScale.Scale = if isSmallScreen then 0.85 else 1
		nonTouchDisplay.ListFrame.Position = UDim2.new(1, -HORIZONTAL_PADDING, 1, -verticalPadding)
	end
end

function ActionManager._initialize()
	assert(not ActionManager._initialized, "ActionManager already initialized!")
	assert(RunService:IsClient(), "ActionManager can only be used on the client!")

	-- Update the position and scale of the list if the TouchGui is added/removed
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" then
			ActionManager._updatePositionAndScale()
		end
	end)

	playerGui.ChildRemoved:Connect(function(child)
		if child.Name == "TouchGui" then
			ActionManager._updatePositionAndScale()
		end
	end)

	-- Update the displayed buttons when the input category changes
	InputCategorizer.lastInputCategoryChanged:Connect(function(inputCategory)
		for _, binding in ActionManager._bindings do
			ActionManager._updateInputDisplay(binding, inputCategory)
		end
	end)

	-- Update the position and scale of the list when the screen size changes or last input category changes
	actionGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ActionManager._updatePositionAndScale)
	InputCategorizer.lastInputCategoryChanged:Connect(ActionManager._updatePositionAndScale)

	-- Parent the UI to the player gui and update its position and scale
	actionGui.Enabled = true
	actionGui.Parent = playerGui
	ActionManager._updatePositionAndScale()

	ActionManager._initialized = true
end

ActionManager._initialize()

return ActionManager