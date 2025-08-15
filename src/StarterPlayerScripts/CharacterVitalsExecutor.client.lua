local CharacterVitalsManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.CharacterVitalsSystem_ScriptStorage.CharacterVitalsManager)

local player = game:GetService("Players").LocalPlayer

local function initCharacterVitals(character: Model)
    local charVitalsObj = CharacterVitalsManager.new(character)

    player.CharacterRemoving:Once(function(_)  
        CharacterVitalsManager.Destroy(charVitalsObj)        
    end
end

local initialCharacter = player.Character
if initialCharacter then
    initCharacterVitals(initialCharacter)
end

player.CharacterAdded:Connect(function(character: Model)  
    initCharacterVitals(character)
end)