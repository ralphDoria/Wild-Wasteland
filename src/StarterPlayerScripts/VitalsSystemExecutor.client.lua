local VitalsManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.VitalsManager)

local player = game:GetService("Players").LocalPlayer

local function initCharacterVitals(character: Model)
    local charVitalsObj = VitalsManager.new(character)

    player.CharacterRemoving:Once(function(_)  
        VitalsManager.Destroy(charVitalsObj)        
    end)
end

local initialCharacter = player.Character
if initialCharacter then
    initCharacterVitals(initialCharacter)
end

player.CharacterAdded:Connect(function(character: Model)  
    initCharacterVitals(character)
end)