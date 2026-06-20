local validateNumber = require(script.Parent.validateNumber)

-- A finite number (rejects NaN and ±infinity) optionally constrained to [min, max] inclusive.
-- This is the validator to use for any client-supplied magnitude — damage, quantity, delay —
-- because validateNumber alone lets math.huge through, which is how `damage = math.huge`
-- one-shot exploits get in (BUGS.md C6).
local function validateBoundedNumber(value: number, min: number?, max: number?): boolean
	if not validateNumber(value) then
		return false
	end

	-- math.huge passes the NaN check in validateNumber, so reject infinities explicitly.
	if value == math.huge or value == -math.huge then
		return false
	end

	if min ~= nil and value < min then
		return false
	end

	if max ~= nil and value > max then
		return false
	end

	return true
end

return validateBoundedNumber
