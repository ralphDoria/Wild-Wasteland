local RS = game:GetService("ReplicatedStorage")
local VitalsSystem_ScriptStorage = RS.RojoManaged_RS.VitalsSystem_ScriptStorage
local References = require(VitalsSystem_ScriptStorage.Data.References)
local Health = require(VitalsSystem_ScriptStorage.Health.HealthManager)
local Hunger = require(VitalsSystem_ScriptStorage.Hunger.HungerManager) 
local Thrist = require(VitalsSystem_ScriptStorage.Thirst.ThirstManager) 

export type VitalsObj = {

}

local VitalsManager = {}

function VitalsManager.new(character: Model)
	References.CharacterStatsGui.Enabled = true

	References.update()
	Health.initialize()
	Hunger.initialize()
	Thrist.initialize()

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

function VitalsManager.Destroy(vitalsObj: VitalsObj)

end

return VitalsManager