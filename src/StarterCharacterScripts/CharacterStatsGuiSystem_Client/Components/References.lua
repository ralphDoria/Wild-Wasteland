local References = {
    player = game:GetService("Players").LocalPlayer,
    character = nil:: Model?,
    humanoid = nil:: Humanoid?,
    StatGuiManager = require("./StatGuiManager"),
    SoundManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ToolSystem_ScriptStorage.Components.Shared.SoundManager),
    InputCategorizer = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ActionManagerSystem.Components.InputCategorizer),
    playerGui = game:GetService("Players").LocalPlayer.PlayerGui:: PlayerGui,
    SoundService = game:GetService("SoundService"),
    debuffSounds = game:GetService("SoundService"):FindFirstChild("Debuff", true):: Folder,
    CharacterStatsGui = nil
}

-- Outside of the table, setting references that depend on other references
References.character = References.player.Character or References.player.CharacterAdded:Wait()
References.humanoid = References.character.Humanoid
References.CharacterStatsGui = References.playerGui:WaitForChild("CharacterStatsGui")

--[[
    This function is to update references dependent on the player's character.
]]
function References.update()
    References.character = References.player.Character or References.player.CharacterAdded:Wait()
    References.humanoid = References.character.Humanoid
    References.CharacterStatsGui = References.playerGui:WaitForChild("CharacterStatsGui")
end

return References