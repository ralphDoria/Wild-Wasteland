local tool = script.Parent.Parent

--Remote Events
local Events = tool:WaitForChild("Events")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local rev_dropped : RemoteEvent = RemoteEvents:WaitForChild("Dropped")

local droppedDetector = tool:WaitForChild("DropDetector")

local SFX_part = tool:WaitForChild("SFX_part")
local softDropSound = SFX_part:WaitForChild("softDrop")
local hardDropSound = SFX_part:WaitForChild("hardDrop")
local DebrisService = game:GetService("Debris")

local softMaterials = {
    Enum.Material.Sand,
    Enum.Material.Fabric,
    Enum.Material.Grass,
    Enum.Material.LeafyGrass
}

local function playSound(soundObject : Sound, delayCorrection : number)
	local soundClone = soundObject:Clone()
	if delayCorrection then
		soundClone.TimePosition = delayCorrection
	end
	soundClone.Parent = SFX_part
	soundClone:Play()
	DebrisService:AddItem(soundClone, soundClone.TimeLength)
end

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
                playSound(softDropSound, 0.4)
                touchedEvent:Disconnect()
            else
                playSound(hardDropSound, 0.1)
                touchedEvent:Disconnect()
            end
        end
        
    end)
end)
