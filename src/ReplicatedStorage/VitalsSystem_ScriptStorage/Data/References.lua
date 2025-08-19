local ReplicatedStorage = game:GetService("ReplicatedStorage")

local References = {
    player = game:GetService("Players").LocalPlayer,
    character = nil:: Model?,
    humanoid = nil:: Humanoid?,
    StatGuiManager = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.SharedComponents.StatGuiManager),
    InputCategorizer = require(ReplicatedStorage.RojoManaged_RS.ActionManagerSystem.Components.InputCategorizer),
    playerGui = game:GetService("Players").LocalPlayer.PlayerGui:: PlayerGui,
    SoundService = game:GetService("SoundService"),
    debuffSounds = game:GetService("SoundService"):FindFirstChild("Debuff", true):: Folder,
    VitalsGui = nil:: ScreenGui?,
    TweenService = game:GetService("TweenService"),
    Trove = require(ReplicatedStorage.Packages.Trove),
}

function References.update(character: Model)
    warn("Updating Vitals System references")
    References.character = character
    References.humanoid = character:WaitForChild("Humanoid")
    References.VitalsGui = References.playerGui:WaitForChild("VitalsGui")
end

return References