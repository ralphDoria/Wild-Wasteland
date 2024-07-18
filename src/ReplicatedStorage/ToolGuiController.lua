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

function toolGuiController.setCurrentAmmoLabels(currentAmmo : number, magCapacity : number)
    currentAmmoLabel.Text = "[" .. tostring(currentAmmo) .. "]/" .. tostring(magCapacity)
end

function toolGuiController.setTotalAmmoLabel(totalAmmo : number)
    totalAmmoLabel.Text = totalAmmo
end

function toolGuiController.connectTotalAmmoUpdateEvent(ammoType : string)
    return player:GetAttributeChangedSignal(ammoType):Connect(function()
        totalAmmoLabel.Text = tostring(player:GetAttribute(ammoType))
    end)
end

function toolGuiController.setAmmoIcon(imageId : string)
    ammoIcon.Image = imageId
end

return toolGuiController