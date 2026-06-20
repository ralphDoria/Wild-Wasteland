-- Shared server-authority boundary (Receivers/Validation): ServerChecks -> Gun -> Components -> Receivers -> Validation
local Validation = require(script.Parent.Parent.Parent.Parent.Validation)
local validateInstance = Validation.isInstance
local validateNumber = Validation.isNumber
local validateCFrame = Validation.isCFrame
local validateSimpleTable = Validation.isSimpleTable

local function taggedValidator(instance: any): boolean
	return validateInstance(instance, "Humanoid")
end

local function validateShootArguments(
	timestamp: number,
	blaster: Tool,
	origin: CFrame,
	tagged: { [string]: Humanoid }
): boolean
	if not validateNumber(timestamp) then
		return false
	end
	if not validateInstance(blaster, "Tool") then
		return false
	end
	if not validateCFrame(origin) then
		return false
	end
	if not validateSimpleTable(tagged, "string", taggedValidator) then
		return false
	end

	return true
end

return validateShootArguments
