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

function ToolGuiManager.toggleToolGuiVisibility(self : ToolGuiManager, tool : Tool, toggle : boolean)
    ToolGui.Enabled = toggle
end

function ToolGuiManager.setTool(tool: Tool)
    if tool:HasTag("Gun") then
        AmmoInfo.Visible = true
        loaded.Text = tostring(tool:GetAttribute("Loaded"))::string
        unloaded.Text = tostring(tool:GetAttribute("Unloaded"))::string
        -- Set loaded and unloaded labels here
    else
        AmmoInfo.Visible = false
        name.Text = tool.Name
        image.Image = tool:GetAttribute("ImageId"):: string -- This right here is a place holder
    end
end

function ToolGuiManager._updatePositionAndScale()
    if InputCategorizer.getLastInputCategory() == "Touch" then
        -- Position gui in upper right corner
        ToolGui
    else
        -- Position gui in bottom right corner

    end
end

function ToolGuiManager.initialize(self: ToolGuiManager)
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

	-- Update the displayed buttons when the input category changes
	InputCategorizer.lastInputCategoryChanged:Connect(function(inputCategory)
		ToolGuiManager._updatePositionAndScale()
	end)

	-- Update the position and scale of the list when the screen size changes or last input category changes
	ToolGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ToolGuiManager._updatePositionAndScale)
	InputCategorizer.lastInputCategoryChanged:Connect(ToolGuiManager._updatePositionAndScale)
end

return ToolGuiManager