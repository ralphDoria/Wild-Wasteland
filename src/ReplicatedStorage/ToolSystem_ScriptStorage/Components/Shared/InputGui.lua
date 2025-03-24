local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ToolGui = game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("ToolGui")
local Controls : Frame = ToolGui.Frame.Controls
local InputTemplate = game:GetService("StarterGui").ToolGui.Templates.InputTemplate

local scrollUp: boolean = false

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

local MouseImage = {
    [Enum.UserInputType.MouseButton1] = "rbxassetid://123442724209547",
    [Enum.UserInputType.MouseButton2] = "rbxassetid://83756052331840",
    [Enum.UserInputType.MouseButton3] = "rbxassetid://108433885610198",
    [Enum.UserInputType.MouseMovement] = "rbxassetid://90580369966962",
    [Enum.UserInputType.MouseWheel] = if scrollUp then "rbxassetid://79615529965042" else "rbxassetid://123334086708640",
}

local AllUserInputTypes = {
    KeyboardAndMouse = {
        "KeyboardAndMouse",
        Enum.UserInputType.MouseButton1,
        Enum.UserInputType.MouseButton2, 
        Enum.UserInputType.MouseButton3,
        Enum.UserInputType.MouseWheel,
        Enum.UserInputType.MouseMovement,
        Enum.UserInputType.Keyboard
    },
    Mobile = {
        "Mobile",
        Enum.UserInputType.Touch,
        Enum.UserInputType.Accelerometer,
        Enum.UserInputType.Gyro

    },
    Gamepad = {
        "Gamepad",
        Enum.UserInputType.Gamepad1,
        Enum.UserInputType.Gamepad2,
        Enum.UserInputType.Gamepad3,
        Enum.UserInputType.Gamepad4,
        Enum.UserInputType.Gamepad5,
        Enum.UserInputType.Gamepad6,
        Enum.UserInputType.Gamepad7,
        Enum.UserInputType.Gamepad8
    },
    Other = {
        "Other",
        Enum.UserInputType.Focus,
        Enum.UserInputType.TextInput,
        Enum.UserInputType.InputMethod,
        Enum.UserInputType.None
    }
}

export type InputGuiObject = {
    Instance : CanvasGroup,
    ActionLabel : TextLabel,
    icon : ImageLabel,
    buttonText : TextLabel,
    buttonImage : ImageLabel,
    progressBar : Frame,
    progress : NumberValue,
    leftGradient : UIGradient,
    rightGradient : UIGradient,
    keycodes : {Enum.UserInputType | Enum.KeyCode},
    cooldownConnection : RBXScriptConnection?,
    connections : {RBXScriptConnection} 
}

local InputGui = {}
function InputGui.new(actionName: string, keycodes: {Enum.UserInputType | Enum.KeyCode}) : InputGuiObject
    local self = {}
    self.Instance = InputTemplate:Clone()
    self.ActionLabel = self.Instance.ActionLabel
	self.icon = self.Instance.InputFrame.Frame.ButtonTextImage -- 
	self.buttonText = self.Instance.InputFrame.Frame.ButtonText
	self.buttonImage = self.Instance.InputFrame.Frame.ButtonImage
    self.progressBar = self.Instance.InputFrame.Frame.ProgressBar
    self.progress = self.progressBar.Progress
    self.leftGradient = self.progressBar.LeftGradient.ProgressBarImage.UIGradient
    self.rightGradient = self.progressBar.RightGradient.ProgressBarImage.UIGradient
    self.keycodes = keycodes
    self.cooldownConnection = nil
    self.connections = {}

    self.Instance.Visible = true
    self.Instance.Parent = Controls
    self.ActionLabel.Text = actionName
    InputGui.setImage(self)

    InputGui._initialize(self)

    return self
end

function InputGui._initialize(self : InputGuiObject)
    table.insert(
        self.connections,
        self.progress.Changed:Connect(function(value)
            local angle = math.clamp(value * 360, 0, 360)
            self.leftGradient.Rotation = math.clamp(angle, 180, 360)
            self.rightGradient.Rotation = math.clamp(angle, 0, 180)
        end)
    )
end

--[[
    More accurate than the _getDeviceFromEnabledInputs function for getting input device, but may return nil.
]]
function InputGui._getDeviceFromLastInputType(lastInputType : Enum.UserInputType) : ("KeyboardAndMouse" | "Mobile" | "Gamepad")?
    for _, v in AllUserInputTypes do
        local index : number? = table.find(v, lastInputType)
        if index then
            local inputClassification = v[1] :: "KeyboardAndMouse" | "Mobile" | "Gamepad" | "Other"
            if inputClassification ~= "Other" then
                return v[1]
            else
                return nil
            end
        end
    end
    return nil
end

--[[
    Less accurate than the _getDeviceFromLastInputType function for getting input device, but always returns a valid input device.
    It's less accurate because, for example, a player on computer using keyboard and mouse inputs may plug in a gamepad and play
    the game using gamepad. From this function's perspective, both gamepad and keyboard inputs are enabled, but this function assumes
    that only one is enabled (expects mutual exclusivity when in reality may not be mutually exclusive).
]]
function InputGui._getDeviceFromEnabledInputs() : "KeyboardAndMouse" | "Mobile" | "Gamepad"
    if UserInputService.GamepadEnabled then
        return "Gamepad"
    elseif UserInputService.KeyboardEnabled then
        return "KeyboardAndMouse"
    elseif UserInputService.TouchEnabled then
        return "Mobile"
    else
        warn("Gamepad, keyboard, and touch inputs aren't enabled, defaulting to computer input icons")
        return "KeyboardAndMouse"
    end
end

--[[
    Uses both _getDeviceFDromLastInputType and _getDeviceFromEnabledInputs().
]]
function InputGui.getDevice() : "KeyboardAndMouse" | "Mobile" | "Gamepad"
    local device : ("KeyboardAndMouse" | "Mobile" | "Gamepad")? = InputGui._getDeviceFromLastInputType(UserInputService:GetLastInputType())
    if device == nil then
        device = InputGui._getDeviceFromEnabledInputs()
    end
    return device :: "KeyboardAndMouse" | "Mobile" | "Gamepad"
end

function InputGui._setImageForKeyboardOrMouseInputs(self : InputGuiObject)
    for _, v in self.keycodes do
        if GamepadButtonImage[v] then
            continue
        end
        if MouseImage[v] then
            self.icon.Size = UDim2.fromOffset(24, 24)
            self.icon.Image = MouseImage[v]
    
            -- Hide ButtonText and ButtonImage, show ButtonTextImage
            self.buttonText.Visible = false
            self.buttonImage.Visible = false
            self.icon.Visible = true
        else
            self.buttonImage.Size = UDim2.fromOffset(28, 30)
    
            -- Show ButtonImage
            self.buttonImage.Visible = true
    
            local buttonTextString : string = UserInputService:GetStringForKeyCode(v)
    
            local buttonTextImage : string? = KeyboardButtonImage[v]
            if buttonTextImage == nil then
                buttonTextImage = KeyboardButtonIconMapping[buttonTextString]
            end
    
            if buttonTextImage == nil then
                local keyCodeMappedText = KeyCodeToTextMapping[v]
                if keyCodeMappedText then
                    buttonTextString = keyCodeMappedText
                end
            end
    
            if buttonTextImage then
                self.icon.Size = UDim2.fromOffset(36, 36)
                self.icon.Image = buttonTextImage
    
                --  Hide ButtonText, show ButtonTextImage
                self.buttonText.Visible = false
                self.icon.Visible = true
            elseif buttonTextString ~= nil and buttonTextString ~= '' then
                if string.len(buttonTextString) > 2 then
                    self.buttonText.TextSize = math.round(self.buttonText.TextSize * 6/7)
                end
                self.buttonText.Text = buttonTextString
    
                -- Hide ButtonTextImage, show ButtonText
                self.icon.Visible = false
                self.buttonText.Visible = true
            else
                error("Keycodes parameter has an unsupported keycode for rendering UI: " .. tostring(self.keycodes))
            end
        end
    end
end

function InputGui.setImage(self : InputGuiObject)
    local device = InputGui.getDevice()
    if device == "Gamepad" then
		for _, v in self.keycodes do
			if GamepadButtonImage[v] then
				self.icon.Size = UDim2.fromOffset(24, 24)
				self.icon.Image = GamepadButtonImage[v]
	
				-- Hide ButtonText and ButtonImage, show ButtonTextImage
				self.buttonText.Visible = false
				self.buttonImage.Visible = false
				self.icon.Visible = true	
			end
		end
	elseif device == "Mobile" then
		self.buttonImage.Size = UDim2.fromOffset(25, 31)
		self.buttonImage.Image = "rbxasset://textures/ui/Controls/TouchTapIcon.png"

		-- Hide ButtonText and ButtonTextImage, show ButtonImage
		self.buttonText.Visible = false
		self.icon.Visible = false
		self.buttonImage.Visible = true	
	elseif device == "KeyboardAndMouse" then
		InputGui._setImageForKeyboardOrMouseInputs(self)
	end
end

function InputGui.Cooldown(self : InputGuiObject, cooldownTime : number)
    self.Instance.GroupTransparency = 0.5
    self.progress.Value = 1
    local timeAccumulated = 0
    if self.cooldownConnection then
        self.cooldownConnection:Disconnect()
        self.cooldownConnection = nil
    end
    self.cooldownConnection = RunService.RenderStepped:Connect(function(dt: number)
        if cooldownTime == timeAccumulated then
            --cooldown timer ended
            if self.cooldownConnection then
               self.cooldownConnection:Disconnect() 
               self.cooldownConnection = nil
            end 
            self.Instance.GroupTransparency = 0
            self.progress.Value = 0
        end
        timeAccumulated = math.clamp(timeAccumulated + dt, 0, cooldownTime)
        self.progress.Value = 1 - (timeAccumulated/cooldownTime)
    end)
end

function InputGui.resetCooldown(self : InputGuiObject)
    if self.cooldownConnection then
        self.cooldownConnection:Disconnect() 
     end 
    self.progress.Value = 0
end

return InputGui