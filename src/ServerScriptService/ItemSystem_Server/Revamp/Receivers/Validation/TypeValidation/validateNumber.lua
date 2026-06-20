-- Canonical: a real Lua number that is not NaN.
-- Note: math.huge / -math.huge PASS this check (they equal themselves). Use
-- validateBoundedNumber when a finite, ranged value is required (e.g. damage).
local function validateNumber(number: number): boolean
	-- Make sure this is actually a number
	if typeof(number) ~= "number" then
		return false
	end

	-- Make sure the number is not NaN
	if number ~= number then
		return false
	end

	return true
end

return validateNumber
