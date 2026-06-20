--[[
	Ownership / character predicates for the server-authority boundary.

	The recurring exploit class in BUGS.md (C10, C11, C13, C7) is the server acting on a tool/
	instance the sender does not own. These helpers answer "does this player legitimately own
	this tool?" so receivers can reject foreign instances before mutating them.

	NOTE: worn accessories tracked outside the character (a server-side WornItems folder) are
	NOT yet covered by ownsTool — that path is added with the wearable batch (C13).
]]

local Ownership = {}

-- The player's character, but only if it exists and is alive. Many receivers index
-- character.PrimaryPart / HumanoidRootPart blindly (BUGS.md H11) — route through this instead.
function Ownership.getAliveCharacter(player: Player): Model?
	local character = player.Character
	if not character then
		return nil
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return nil
	end

	return character
end

-- True if `tool` is a Tool the player currently owns: equipped (under their character) or
-- stowed in their Backpack. Guards against fake-table imposters via the Instance/IsA check.
function Ownership.ownsTool(player: Player, tool: Instance): boolean
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return false
	end

	local character = player.Character
	if character and tool:IsDescendantOf(character) then
		return true
	end

	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and tool:IsDescendantOf(backpack) then
		return true
	end

	return false
end

-- Stricter variant: true only if the tool is currently equipped (directly parented to the
-- player's character). Use where "equipped" specifically matters (firing, swinging).
function Ownership.ownsEquippedTool(player: Player, tool: Instance): boolean
	if typeof(tool) ~= "Instance" or not tool:IsA("Tool") then
		return false
	end

	local character = player.Character
	return character ~= nil and tool.Parent == character
end

return Ownership
