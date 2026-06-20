--!strict
--[[
	Pure stackable arithmetic, extracted from StackableReceiver so the merge/transfer math is
	unit-testable in isolation (TestEZ: StackableMath.spec). No Instances, no remotes, no yielding —
	just numbers in, numbers out.

	Guards BUGS.md C7 (negative-transfer duplication): the range validation that used to be a single
	`assert(... quantityToTransfer < originalSourceQuantity)` — which let negative amounts through and
	duplicated stacks — is now a tested predicate (`canTransfer`).
]]

local StackableMath = {}

-- Merge `sourceQuantity` into `destinationQuantity`, capped at `maxQuantity`.
-- Returns the destination's new quantity, the source's leftover (excess) quantity, and whether the
-- source stack is now depleted and should be destroyed by the caller.
function StackableMath.merge(
	sourceQuantity: number,
	destinationQuantity: number,
	maxQuantity: number
): (number, number, boolean)
	local result = sourceQuantity + destinationQuantity
	local newDestination = math.min(result, maxQuantity)
	local excess = result - maxQuantity
	local destroySource = excess <= 0
	return newDestination, excess, destroySource
end

-- A transfer reassigns the combined pool (source + destination) so the destination ends holding
-- exactly `amount`, with the remainder left in the source. Valid only when `amount` is a whole
-- number in [0, pool):
--   * the strict upper bound keeps at least 1 in the source (preserving the pre-existing contract);
--   * the >= 0 lower bound rejects the negative-transfer DUPE (C7) while still allowing the
--     legitimate `transfer 0` cleanup (SplittingMenuManager.lua:119).
function StackableMath.canTransfer(
	sourceQuantity: number,
	destinationQuantity: number,
	amount: number
): boolean
	if type(amount) ~= "number" or amount ~= amount or amount % 1 ~= 0 then
		return false -- non-number, NaN, or fractional
	end
	local pool = sourceQuantity + destinationQuantity
	return amount >= 0 and amount < pool
end

-- Apply a transfer assumed valid (call `canTransfer` first). Returns (newSource, newDestination).
function StackableMath.transfer(
	sourceQuantity: number,
	destinationQuantity: number,
	amount: number
): (number, number)
	local pool = sourceQuantity + destinationQuantity
	return pool - amount, amount
end

return StackableMath
