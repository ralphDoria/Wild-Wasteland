--[[
	Shared server-authority validation boundary (Tier 2 — see docs/BUGFIX_STRATEGY.md).

	Single source of truth for the type- and ownership-checks every receiver routes client
	input through, instead of each remote re-deriving them ad hoc. Modeled on (and absorbing)
	the gun path's TypeValidation pattern, which was previously the only validated remote.

	Usage:
		local Validation = require(<...>.Receivers.Validation)
		if not Validation.isInstance(tool, "Tool") then return end
		if not Validation.ownsTool(player, tool) then return end
		if not Validation.isInteger(amount, 1) then return end   -- positive whole number
]]

local TypeValidation = script.TypeValidation
local Ownership = require(script.Ownership)

local Validation = {
	-- Pure type validators
	isNumber = require(TypeValidation.validateNumber),
	isBoundedNumber = require(TypeValidation.validateBoundedNumber),
	isInteger = require(TypeValidation.validateInteger),
	isInstance = require(TypeValidation.validateInstance),
	isVector3 = require(TypeValidation.validateVector3),
	isCFrame = require(TypeValidation.validateCFrame),
	isSimpleTable = require(TypeValidation.validateSimpleTable),

	-- Ownership / character helpers
	getAliveCharacter = Ownership.getAliveCharacter,
	ownsTool = Ownership.ownsTool,
	ownsEquippedTool = Ownership.ownsEquippedTool,
}

return Validation
