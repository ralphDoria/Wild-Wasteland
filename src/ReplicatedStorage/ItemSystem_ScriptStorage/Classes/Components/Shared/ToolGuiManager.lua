local UserInputService = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local InputCategorizer = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ActionManagerSystem.Components.InputCategorizer)

local ToolGui: ScreenGui = playerGui:WaitForChild("ToolGui")
local frame: Frame = ToolGui:FindFirstChild("Frame"):: Frame
local AmmoInfo: Frame = frame:FindFirstChild("AmmoInfo"):: Frame
local loaded: TextLabel = AmmoInfo:FindFirstChild("Loaded"):: TextLabel
local unloaded: TextLabel = AmmoInfo:FindFirstChild("Unloaded"):: TextLabel
local Toolinfo: Frame = frame:FindFirstChild("ToolInfo"):: Frame
local name: TextLabel = Toolinfo:FindFirstChild("Name"):: TextLabel
local image: ImageLabel = Toolinfo:FindFirstChild("Image"):: ImageLabel

export type ToolGuiManager = {
    connections : {RBXScriptConnection}
    --Probably should create gui instances first in Roblox Studio before trying to code in their functionality.
}

local ToolGuiManager = {
    _initialized = false
}

function ToolGuiManager.setTool(tool: Tool)
    name.Text = tool.Name
    image.Image = tool:GetAttribute("ToolGuiImageId"):: string
    if tool:HasTag("Gun") then
        AmmoInfo.Visible = true
        loaded.Text = tostring(tool:GetAttribute("Loaded"))::string
        unloaded.Text = tostring(tool:GetAttribute("Unloaded"))::string
        -- Set loaded and unloaded labels here
    else
        AmmoInfo.Visible = false
    end
end

--[[
    @note: The two functions below are whole functions just in case in the future I decide to animate the frame in/out.
]]
function ToolGuiManager.show()
    ToolGui.Enabled = true
end

function ToolGuiManager.hide()
    ToolGui.Enabled = false
end

function ToolGuiManager._updatePositionAndScale()
    local touchControlsEnabled = playerGui:FindFirstChild("TouchGui") ~= nil
	-- This is the same calculation used by the TouchGui for sizing the jump button
	local minScreenSize = math.min(ToolGui.AbsoluteSize.X, ToolGui.AbsoluteSize.Y)
	local isSmallScreen = minScreenSize < 500 -- This may be incorporated later

	if touchControlsEnabled and InputCategorizer.getLastInputCategory() == InputCategorizer.InputCategory.Touch then
		-- Position gui in upper right corner
        frame.AnchorPoint = Vector2.new(1, 0)
        frame.Position = UDim2.fromScale(1, 0)
	else
         -- Position gui in bottom right corner
         frame.AnchorPoint = Vector2.new(1, 1)
         frame.Position = UDim2.fromScale(1, 1)
	end
end

function ToolGuiManager._initialize()
    -- Update the position and scale of the list if the TouchGui is added/removed
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" then
			ToolGuiManager._updatePositionAndScale()
		end
	end)

	playerGui.ChildRemoved:Connect(function(child)
		if child.Name == "TouchGui" then
			ToolGuiManager._updatePositionAndScale()
		end
	end)

	-- Update the position and scale of the list when the screen size changes or last input category changes
	ToolGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ToolGuiManager._updatePositionAndScale)
	InputCategorizer.lastInputCategoryChanged:Connect(ToolGuiManager._updatePositionAndScale)

    ToolGuiManager.hide()
end

ToolGuiManager._initialize()

return ToolGuiManager