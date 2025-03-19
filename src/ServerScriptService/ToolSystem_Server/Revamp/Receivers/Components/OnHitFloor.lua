local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
local ToolInfo = require(ReplicatedStorage:FindFirstChild("ToolInfo", true))
local softMaterials = {
    Enum.Material.Sand,
    Enum.Material.Fabric,
    Enum.Material.Grass,
    Enum.Material.LeafyGrass,
    Enum.Material.Snow
}

local function checkSoftMaterial(part: BasePart): boolean
    for _, material in softMaterials do
        if part.Material == material then
            return true
        end
    end
    return false
end

return function(tool : Tool)
    local BodyAttach = tool:FindFirstChild("BodyAttach")
    local soundObjects = ToolInfo.get(tool.Name).soundObjects
    local touchedEvent
    touchedEvent = BodyAttach.Touched:Connect(function(partThatTouched)
        if partThatTouched.Parent:FindFirstChild("Humanoid") == nil and partThatTouched:FindFirstAncestorOfClass("Tool") == nil and partThatTouched.Name ~= "ColliderPart" then
            local isOnSoftMaterial = checkSoftMaterial(partThatTouched)
            if isOnSoftMaterial then
                playSound(soundObjects.drop.soft, BodyAttach, 0)
                touchedEvent:Disconnect()
            else
                playSound(soundObjects.drop.hard, BodyAttach, 0)
                touchedEvent:Disconnect()
            end
        end
        
    end)
end