------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local tool = script.Parent.Parent
local droppedDetector = tool:WaitForChild("DropDetector")

------------------------------------------------------------------------<<<ROBLOX LIBRARIES & SERVICES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

------------------------------------------------------------------------<<<REMOTE & BINDABLE EVENTS>>>
local Events = tool:WaitForChild("Events")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local rev_dropped : RemoteEvent = RemoteEvents:WaitForChild("Dropped")

------------------------------------------------------------------------<<<SFX>>>
local SFX_part = tool:WaitForChild("SFX_part")
local softDropSound = SFX_part:WaitForChild("softDrop")
local hardDropSound = SFX_part:WaitForChild("hardDrop")

local softMaterials = {
    Enum.Material.Sand,
    Enum.Material.Fabric,
    Enum.Material.Grass,
    Enum.Material.LeafyGrass,
    Enum.Material.Snow
}

rev_dropped.OnServerEvent:Connect(function(player)
    tool.Parent = game.Workspace
    local touchedEvent
    touchedEvent = droppedDetector.Touched:Connect(function(partThatTouched)
        local isOnSoftMaterial = false
        if partThatTouched.Parent:FindFirstChild("Humanoid") == nil then
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
end)
