local UserInputService = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui

local scrollUp: boolean = false

local MouseImage = {
    [Enum.UserInputType.MouseButton1] = "rbxassetid://123442724209547",
    [Enum.UserInputType.MouseButton2] = "rbxassetid://83756052331840",
    [Enum.UserInputType.MouseButton3] = "rbxassetid://108433885610198",
    [Enum.UserInputType.MouseMovement] = "rbxassetid://90580369966962",
    [Enum.UserInputType.MouseWheel] = if scrollUp then "rbxassetid://79615529965042" else "rbxassetid://123334086708640",
}

local GamepadButtonImage = {
	[Enum.KeyCode.ButtonX] = "rbxasset://textures/ui/Controls/xboxX.png",
	[Enum.KeyCode.ButtonY] = "rbxasset://textures/ui/Controls/xboxY.png",
	[Enum.KeyCode.ButtonA] = "rbxasset://textures/ui/Controls/xboxA.png",
	[Enum.KeyCode.ButtonB] = "rbxasset://textures/ui/Controls/xboxB.png",
	[Enum.KeyCode.DPadLeft] = "rbxasset://textures/ui/Controls/dpadLeft.png",
	[Enum.KeyCode.DPadRight] = "rbxasset://textures/ui/Controls/dpadRight.png",
	[Enum.KeyCode.DPadUp] = "rbxasset://textures/ui/Controls/dpadUp.png",
	[Enum.KeyCode.DPadDown] = "rbxasset://textures/ui/Controls/dpadDown.png",
	[Enum.KeyCode.ButtonSelect] = "rbxasset://textures/ui/Controls/xboxmenu.png",
	[Enum.KeyCode.ButtonL1] = "rbxasset://textures/ui/Controls/xboxLB.png",
	[Enum.KeyCode.ButtonR1] = "rbxasset://textures/ui/Controls/xboxRB.png",
	[Enum.KeyCode.ButtonL2] = "rbxasset://textures/ui/Controls/xboxLT.png",
	[Enum.KeyCode.ButtonR2] = "rbxasset://textures/ui/Controls/xboxRT.png",
	[Enum.KeyCode.ButtonL3] = "rbxasset://textures/ui/Controls/xboxLS.png",
	[Enum.KeyCode.ButtonL3] = "rbxasset://textures/ui/Controls/xboxRS.png"
}

local KeyboardButtonImage = {
	[Enum.KeyCode.Backspace] = "rbxasset://textures/ui/Controls/backspace.png",
	[Enum.KeyCode.Return] = "rbxasset://textures/ui/Controls/return.png",
	[Enum.KeyCode.LeftShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.RightShift] = "rbxasset://textures/ui/Controls/shift.png",
	[Enum.KeyCode.Tab] = "rbxasset://textures/ui/Controls/tab.png",
}

local KeyboardButtonIconMapping = {
	["'"] = "rbxasset://textures/ui/Controls/apostrophe.png",
	[","] = "rbxasset://textures/ui/Controls/comma.png",
	["`"] = "rbxasset://textures/ui/Controls/graveaccent.png",
	["."] = "rbxasset://textures/ui/Controls/period.png",
	[" "] = "rbxasset://textures/ui/Controls/spacebar.png",
}

local KeyCodeToTextMapping = {
	[Enum.KeyCode.LeftControl] = "Ctrl",
	[Enum.KeyCode.RightControl] = "Ctrl",
	[Enum.KeyCode.LeftAlt] = "Alt",
	[Enum.KeyCode.RightAlt] = "Alt",
	[Enum.KeyCode.F1] = "F1",
	[Enum.KeyCode.F2] = "F2",
	[Enum.KeyCode.F3] = "F3",
	[Enum.KeyCode.F4] = "F4",
	[Enum.KeyCode.F5] = "F5",
	[Enum.KeyCode.F6] = "F6",
	[Enum.KeyCode.F7] = "F7",
	[Enum.KeyCode.F8] = "F8",
	[Enum.KeyCode.F9] = "F9",
	[Enum.KeyCode.F10] = "F10",
	[Enum.KeyCode.F11] = "F11",
	[Enum.KeyCode.F12] = "F12",
}

local ToolGui = playerGui:WaitForChild("ToolGui")
local Controls : Frame = ToolGui.Frame.Controls
local InputTemplate = game:GetService("StarterGui").ToolGui.Templates.InputTemplate

export type InputGuiObject = {
    Instance : Frame,
    ActionLabel : TextLabel
}

export type ToolGuiManager = {
    gui : ScreenGui,
    Device : "Mobile" | "Gamepad" | "Computer",
    InputGuis : {[string] : InputGuiObject},
    connections : {RBXScriptConnection}
    --Probably should create gui instances first in Roblox Studio before trying to code in their functionality.
}

local ToolGuiManager = {}

function ToolGuiManager.new() : ToolGuiManager
    local self : ToolGuiManager = {
        gui = ToolGui,
        Device = ToolGuiManager.getInputDevice(),
        InputGuis = {},
        connections = {}
    }

    self.gui.Enabled = true

    ToolGuiManager.initialize(self)
    return self
end

function ToolGuiManager.initialize(self: ToolGuiManager)
    table.insert(
        self.connections,
        UserInputService.LastInputTypeChanged:Connect(function(a0: Enum.UserInputType)  
            
        end)
    )
end

function ToolGuiManager.getInputDevice() : "Mobile" | "Gamepad" | "Computer"
    if UserInputService.GamepadEnabled then
        return "Gamepad"
    elseif UserInputService.KeyboardEnabled then
        return "Computer"
    elseif UserInputService.TouchEnabled then
        return "Mobile"
    else
        warn("No inputs enabled, defaulting to computer inputs")
        return "Computer"
    end
end

function ToolGuiManager.CreateInputGui(self: ToolGuiManager, actionName: string, keycodes: {Enum.UserInputType | Enum.KeyCode})
    local clone = InputTemplate:Clone()
    local inputGui : InputGuiObject = {
        Instance = clone,
        ActionLabel = clone:FindFirstChild("ActionName")
    }
    self.InputGuis[actionName] = inputGui
    clone.Visible = true
    clone.Parent = Controls
    inputGui.ActionLabel.Text = actionName

	local icon = clone.InputFrame.Frame.ButtonTextImage
	local buttonText = clone.InputFrame.Frame.ButtonText
	local buttonImage = clone.InputFrame.Frame.ButtonImage

    if self.Device == "Gamepad" then
		for _, v in keycodes do
			if GamepadButtonImage[v] then
				setupIconTweens()
				icon.Size = UDim2.fromOffset(24, 24)
				icon.Image = GamepadButtonImage[v]
	
				-- Hide ButtonText and ButtonImage, show ButtonTextImage
				buttonText.Visible = false
				buttonImage.Visible = false
				icon.Visible = true	
			end
		end
	elseif self.Device == "Mobile" then
		setupButtonImageTweens()
		buttonImage.Size = UDim2.fromOffset(25, 31)
		buttonImage.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"

		-- Hide ButtonText and ButtonTextImage, show ButtonImage
		buttonText.Visible = false
		icon.Visible = false
		buttonImage.Visible = true	
	else
		local keyboardKeycode = nil
		local mouseInput = nil
		for _, v in keycodes do
			if GamepadButtonImage[v] then
				continue
			end
			if MouseImage[v] then
				
			end
		end
		setupButtonImageTweens()
		buttonImage.Size = UDim2.fromOffset(28, 30)

		-- Show ButtonImage
		buttonImage.Visible = true

		local buttonTextString : string? = UserInputService:GetStringForKeyCode(prompt.KeyboardKeyCode)

		local buttonTextImage : Enum.KeyCode? = KeyboardButtonImage[prompt.KeyboardKeyCode]
		if buttonTextImage == nil then
			buttonTextImage = KeyboardButtonIconMapping[buttonTextString]
		end

		if buttonTextImage == nil then
			local keyCodeMappedText = KeyCodeToTextMapping[prompt.KeyboardKeyCode]
			if keyCodeMappedText then
				buttonTextString = keyCodeMappedText
			end
		end

		if buttonTextImage then
			setupIconTweens()
			icon.Size = UDim2.fromOffset(36, 36)
			icon.Image = buttonTextImage

			--  Hide ButtonText, show ButtonTextImage
			buttonText.Visible = false
			icon.Visible = true
		elseif buttonTextString ~= nil and buttonTextString ~= '' then
			if string.len(buttonTextString) > 2 then
				buttonText.TextSize = math.round(buttonText.TextSize * 6/7)
			end
			setupButtonTextTweens()
			buttonText.Text = buttonTextString

			-- Hide ButtonTextImage, show ButtonText
			icon.Visible = false
			buttonText.Visible = true
		else
			error("ProximityPrompt '" .. prompt.Name .. "' has an unsupported keycode for rendering UI: " .. tostring(prompt.KeyboardKeyCode))
		end
	end

    --setting up InputFrame
end

return ToolGuiManager