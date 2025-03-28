local UserInputService = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local InputCategorizer = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ActionManagerSystem.Components.InputCategorizer)

local ToolGui = playerGui:WaitForChild("ToolGui")
local AmmoInfo: Frame = ToolGui.Frame.AmmoInfo
local loaded: TextLabel = AmmoInfo:FindFirstChild("Loaded"):: TextLabel
local unloaded: TextLabel = AmmoInfo:FindFirstChild("Unloaded"):: TextLabel
local Toolinfo: Frame = ToolGui.Frame.ToolInfo
local name: TextLabel = Toolinfo:FindFirstChild("Name"):: TextLabel
local image: ImageLabel = Toolinfo:FindFirstChild("Image"):: ImageLabel

export type ToolGuiManager = {
    connections : {RBXScriptConnection}
    --Probably should create gui instances first in Roblox Studio before trying to code in their functionality.
}

local ToolGuiManager = {
    _initialized = false
}

function ToolGuiManager.initialize(self: ToolGuiManager)
end

function ToolGuiManager.toggleToolGuiVisibility(self : ToolGuiManager, tool : Tool, toggle : boolean)
    ToolGui.Enabled = toggle
end

return ToolGuiManager