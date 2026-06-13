local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playSound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)
local ToolInfo = require(ReplicatedStorage:FindFirstChild("ToolInfo", true))
local softMaterials = {
    Enum.Material.Sand,
    Enum.Material.Fabric,
    Enum.Material.Grass,
    Enum.Material.LeafyGrass,
    Enum.Material.Snow,
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
    local BodyAttach = tool:FindFirstChild("BodyAttach", true)
    if not BodyAttach then return end
    local soundObjects = ToolInfo.get(tool.Name).soundObjects
    local touchedEvent
    touchedEvent = BodyAttach.Touched:Connect(function(partThatTouched)
        local touchedParent = partThatTouched.Parent
        if touchedParent == nil then return end
        if touchedParent:FindFirstChild("Humanoid") == nil and partThatTouched:FindFirstAncestorOfClass("Tool") == nil then
            local isOnSoftMaterial = checkSoftMaterial(partThatTouched)
            if isOnSoftMaterial then
                -- warn("hit floor: soft material: ", partThatTouched, partThatTouched.Parent)
                playSound(soundObjects.drop.soft, BodyAttach)
                touchedEvent:Disconnect()
            else
                playSound(soundObjects.drop.hard, BodyAttach)
                touchedEvent:Disconnect()
            end
        end
        
    end)
end