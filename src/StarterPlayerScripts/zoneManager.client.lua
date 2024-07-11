local SoundService = game:GetService("SoundService")
local ambience_vault = SoundService:FindFirstChild("Facility Ambience 1 Alternate", true)
local ambience_desert = SoundService:FindFirstChild("Desert Ambience", true)

local zones : Folder = workspace.Zones

local Zone = require(game:GetService("ReplicatedStorage"):FindFirstChild("Zone", true))

ambience_desert:Play()

local vaultInteriorZones = Zone.new(zones.vaultInterior)
vaultInteriorZones:relocate()
vaultInteriorZones.localPlayerEntered:Connect(function()
    ambience_vault:Play()
    ambience_desert:Stop()
end)

vaultInteriorZones.localPlayerExited:Connect(function()
    ambience_vault:Stop()
    ambience_desert:Play()
end)

