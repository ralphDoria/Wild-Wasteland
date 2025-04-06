local References = require("./Components/References")
local Health = require("./Components/Health")
local Stamina = require("../MovementAndStaminaSystem_Client/Modules/StaminaManager")

local Config: {[string]: Color3} = {
    ["Health"] = Color3.fromRGB(255, 0, 0),
    ["Stamina"] = Color3.fromRGB(255, 145, 0),
    ["Hunger"] = Color3.fromRGB(255, 234, 0),
    ["Thirst"] = Color3.fromRGB(0, 17, 255)
}

local function initialize()
	References.update()
	Health.initialize()
	Stamina.initialize()

	local function updatePositionAndScale()
		local touchControlsEnabled = References.playerGui:FindFirstChild("TouchGui") ~= nil
		-- This is the same calculation used by the TouchGui for sizing the jump button
		local minScreenSize = math.min(References.CharacterStatsGui.AbsoluteSize.X, References.CharacterStatsGui.AbsoluteSize.Y)
		local isSmallScreen = minScreenSize < 500 -- This may be incorporated later
	
		if touchControlsEnabled and References.InputCategorizer.getLastInputCategory() == References.InputCategorizer.InputCategory.Touch then
			-- Position gui in upper left corner
			References.CharacterStatsGui.Frame.AnchorPoint = Vector2.new(0, 0)
			References.CharacterStatsGui.Frame.Position = UDim2.fromScale(0, 0)
		else
			 -- Position gui in bottom right corner
			 References.CharacterStatsGui.Frame.AnchorPoint = Vector2.new(0, 1)
			 References.CharacterStatsGui.Frame.Position = UDim2.fromScale(0, 1)
		end
	end

    -- Update the position and scale of the list if the TouchGui is added/removed
	References.playerGui.ChildAdded:Connect(function(child)
		if child.Name == "TouchGui" then
			updatePositionAndScale()
		end
	end)

	References.playerGui.ChildRemoved:Connect(function(child)
		if child.Name == "TouchGui" then
			updatePositionAndScale()
		end
	end)

	-- Update the position and scale of the list when the screen size changes or last input category changes
	References.CharacterStatsGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updatePositionAndScale)
	References.InputCategorizer.lastInputCategoryChanged:Connect(updatePositionAndScale)
end

initialize()


