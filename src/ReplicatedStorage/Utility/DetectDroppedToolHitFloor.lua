------------------------------------------------------------------------<<<ROBLOX LIBRARIES & SERVICES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

------------------------------------------------------------------------<<<SFX>>>
local sharedToolSounds = ReplicatedStorage.Tools.Shared.BasicSounds
local hardDropSound = sharedToolSounds.hardDrop
local softDropSound = sharedToolSounds.softDrop
local softMaterials = {
    Enum.Material.Sand,
    Enum.Material.Fabric,
    Enum.Material.Grass,
    Enum.Material.LeafyGrass,
    Enum.Material.Snow
}

return function(tool : Tool)
    --<<<Specific Parts>>>--
    local droppedDetector = tool:FindFirstChild("DropDetector")
    --<<<SFX>>>--
    local SFX_part = if tool:FindFirstChild("SFX_part") then tool:FindFirstChild("SFX_part") else tool:FindFirstChild("BodyAttach", true)
    --<<<Even Connection>>>--
    local touchedEvent
    touchedEvent = droppedDetector.Touched:Connect(function(partThatTouched)
        local isOnSoftMaterial = false
        if partThatTouched.Parent:FindFirstChild("Humanoid") == nil and partThatTouched:FindFirstAncestorOfClass("Tool") == nil and partThatTouched.Name ~= "ColliderPart" then
            for _, material in softMaterials do
                if partThatTouched.Material == material then
                    isOnSoftMaterial = true
                end
            end
            if isOnSoftMaterial then
                playSound(softDropSound, SFX_part, 0.4)
                touchedEvent:Disconnect()
            else
                playSound(hardDropSound, SFX_part, 0.1)
                touchedEvent:Disconnect()
            end
        end
        
    end)
end