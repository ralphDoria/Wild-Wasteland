------------------------------------------------------------------------<<<ROBLOX LIBRARIES & SERVICES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

------------------------------------------------------------------------<<<SFX>>>
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
    local SFX_part = tool:WaitForChild("SFX_part")
    local softDropSound = SFX_part:WaitForChild("softDrop")
    local hardDropSound = SFX_part:WaitForChild("hardDrop")
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
                playSound(softDropSound, 0.4, SFX_part)
                touchedEvent:Disconnect()
            else
                playSound(hardDropSound, 0.1, SFX_part)
                touchedEvent:Disconnect()
            end
        end
        
    end)
end