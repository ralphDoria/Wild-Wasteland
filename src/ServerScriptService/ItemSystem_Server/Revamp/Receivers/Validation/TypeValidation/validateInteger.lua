local validateBoundedNumber = require(script.Parent.validateBoundedNumber)

-- A finite whole number, optionally constrained to [min, max] inclusive.
-- Use for counts/quantities (stackable transfers, ammo) where fractional or infinite
-- values are nonsensical and exploitable (BUGS.md C7).
local function validateInteger(value: number, min: number?, max: number?): boolean
	if not validateBoundedNumber(value, min, max) then
		return false
	end

	if value % 1 ~= 0 then
		return false
	end

	return true
end

return validateInteger
