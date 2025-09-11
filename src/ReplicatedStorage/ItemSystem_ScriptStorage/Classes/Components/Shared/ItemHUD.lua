local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local InputCategorizer = require(ReplicatedStorage.RojoManaged_RS.ActionManagerSystem.Components.InputCategorizer)
local Constants = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Gun.Constants)


local itemHudGui: ScreenGui = playerGui:WaitForChild("ItemHUD")
local frame: Frame = itemHudGui:FindFirstChild("Frame"):: Frame
local AmmoInfo: Frame = frame:FindFirstChild("AmmoInfo"):: Frame
local loaded: TextLabel = AmmoInfo:FindFirstChild("Loaded"):: TextLabel
local unloaded: TextLabel = AmmoInfo:FindFirstChild("Unloaded"):: TextLabel
local Toolinfo: Frame = frame:FindFirstChild("ToolInfo"):: Frame
local name: TextLabel = Toolinfo:FindFirstChild("Name"):: TextLabel
local image: ImageLabel = Toolinfo:FindFirstChild("Image"):: ImageLabel

export type ItemHUD = {
    connections : {RBXScriptConnection}
    --Probably should create gui instances first in Roblox Studio before trying to code in their functionality.
}

local ItemHUD = {
    _initialized = false
}

function ItemHUD.setTool(tool: Tool)
    name.Text = tool.Name
    image.Image = tool:GetAttribute("ToolGuiImageId"):: string
    if tool:GetAttribute("_ammo") then
        loaded.Text = tostring(tool:GetAttribute(Constants.AMMO_ATTRIBUTE))::string
        unloaded.Text = tostring(tool:GetAttribute(Constants.MAGAZINE_SIZE_ATTRIBUTE))::string
        -- ammoReserveLabel.Text = 
        AmmoInfo.Visible = true
    else
        AmmoInfo.Visible = false
    end
end

function ItemHUD.setAmmo(num: number)
    warn("NOT IMPLEMENTED YET")
end

function ItemHUD.setMagazineSize(num: number)
    warn("NOT IMPLEMENTED YET")
end

function ItemHUD.setAmmoReserve(num: number)
    warn("NOT IMPLEMENTED YET")
end

function ItemHUD.setReloading(toggle: boolean)
    warn("NOT IMPLEMENTED YET")
end

--[[
    @note: The two functions below are whole functions just in case in the future I decide to animate the frame in/out.
]]
function ItemHUD.show()
    itemHudGui.Enabled = true
end

function ItemHUD.hide()
    itemHudGui.Enabled = false
end

function ItemHUD._updatePositionAndScale()
    local touchControlsEnabled = playerGui:FindFirstChild("TouchGui") ~= nil
	-- This is the same calculation used by the TouchGui for sizing the jump button
	local minScreenSize = math.min(itemHudGui.AbsoluteSize.X, itemHudGui.AbsoluteSize.Y)
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

function ItemHUD._initialize()
    -- Update the position and scale of the list if the TouchGui is added/removed
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" then
			ItemHUD._updatePositionAndScale()
		end
	end)

	playerGui.ChildRemoved:Connect(function(child)
		if child.Name == "TouchGui" then
			ItemHUD._updatePositionAndScale()
		end
	end)

	-- Update the position and scale of the list when the screen size changes or last input category changes
	itemHudGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(ItemHUD._updatePositionAndScale)
	InputCategorizer.lastInputCategoryChanged:Connect(ItemHUD._updatePositionAndScale)

    ItemHUD.hide()
end

ItemHUD._initialize()

return ItemHUD