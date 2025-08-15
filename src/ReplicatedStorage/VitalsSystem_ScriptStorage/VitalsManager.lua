--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VitalsSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage
local References = require(VitalsSystem_ScriptStorage.Data.References)
local HealthManager = require(VitalsSystem_ScriptStorage.Health.HealthManager)
local HungerThirstManager = require(VitalsSystem_ScriptStorage.HungerThirst.HungerThirstManager) 
local Trove = require(ReplicatedStorage.Packages.Trove)

export type VitalsObj = {
	healthObject: HealthManager.HealthObject,
	-- hungerObject: Hunger.hungerObject,
	thirstObject: HungerThirstManager.hungerThirstObject,
	hungerObject: HungerThirstManager.hungerThirstObject,
	trove: any
}

local VitalsManager = {}

function VitalsManager.new(character: Model): VitalsObj
	References.update(character)
	References.VitalsGui.Enabled = true

	local trove = Trove.new()
	local self: VitalsObj = {
		healthObject = HealthManager.new(),
		hungerObject = HungerThirstManager.new("Hunger"),
		thirstObject = HungerThirstManager.new("Thirst"),
		trove = trove
	}

	local function updatePositionAndScale()
		local touchControlsEnabled = References.playerGui:FindFirstChild("TouchGui") ~= nil
		-- This is the same calculation used by the TouchGui for sizing the jump button
		local minScreenSize = math.min(References.VitalsGui.AbsoluteSize.X, References.VitalsGui.AbsoluteSize.Y)
		local isSmallScreen = minScreenSize < 500 -- This may be incorporated later
	
		if touchControlsEnabled and References.InputCategorizer.getLastInputCategory() == References.InputCategorizer.InputCategory.Touch then
			-- Position gui in upper left corner
			References.VitalsGui.Frame.AnchorPoint = Vector2.new(0, 0)
			References.VitalsGui.Frame.Position = UDim2.fromScale(0, 0)
		else
			 -- Position gui in bottom right corner
			 References.VitalsGui.Frame.AnchorPoint = Vector2.new(0, 1)
			 References.VitalsGui.Frame.Position = UDim2.fromScale(0, 1)
		end
	end

    -- Update the position and scale of the list if the TouchGui is added/removed
	trove:Connect(References.playerGui.ChildAdded, function(child)
			if child.Name == "TouchGui" then
				updatePositionAndScale()
			end
		end
	)

	trove:Connect(References.playerGui.ChildRemoved, function(child)
			if child.Name == "TouchGui" then
				updatePositionAndScale()
			end
		end
	)

	-- Update the position and scale of the list when the screen size changes or last input category changes
	trove:Connect(References.VitalsGui:GetPropertyChangedSignal("AbsoluteSize"), updatePositionAndScale)
	trove:Connect(References.InputCategorizer.lastInputCategoryChanged, updatePositionAndScale)

	return self
end

function VitalsManager.Destroy(vitalsObj: VitalsObj)
	HealthManager.Destroy(vitalsObj.healthObject)	
	HungerThirstManager.Destroy(vitalsObj.thirstObject)
	HungerThirstManager.Destroy(vitalsObj.hungerObject)
	vitalsObj.trove:Destroy()
end

return VitalsManager