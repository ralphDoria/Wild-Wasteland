local TweenService = game:GetService("TweenService")

local player = game:GetService("Players").LocalPlayer
local ToolGui = player.PlayerGui.ToolGui

local nameLabel : TextLabel = ToolGui:FindFirstChild("Name", true)
local currentAmmoLabel : TextLabel = ToolGui:FindFirstChild("currentAmmo", true)
local totalAmmoLabel : TextLabel = ToolGui:FindFirstChild("totalAmmo", true)
local ammoIcon : ImageLabel = ToolGui:FindFirstChild("ammoIcon", true)

local toolGuiController = {}

function toolGuiController.setGuiEnabled(set : boolean)
    ToolGui.Enabled = set
end

function toolGuiController.setNameLabel(name : string)
    nameLabel.Text = name
end

function toolGuiController.setAmmoLabels(currentAmmo : number, totalAmmo : number)
    currentAmmoLabel.Text = tostring(currentAmmo)
    totalAmmoLabel.Text = tostring(totalAmmo)
end

return toolGuiController