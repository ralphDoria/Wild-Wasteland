local Constants = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Gun.Constants)

local function validateReload(player: Player, blaster: Tool): boolean
	local character = player.Character
	if not character then
		return false
	end

	if blaster.Parent ~= character then
		return false
	end

	return true
end

return validateReload
