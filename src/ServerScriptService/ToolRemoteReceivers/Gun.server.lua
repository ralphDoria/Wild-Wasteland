local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ vfx objects
local healingLiquidSquirt = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("VFX"):WaitForChild("Blood") 
local damageIndicator = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("VFX"):WaitForChild("damageIndicator")
]]

local detectDroppedToolHitFloor = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("DetectDroppedToolHitFloor"))
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

local gunRemotes : Folder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Gun"):WaitForChild("Remotes")
local rev_playSound : RemoteEvent = gunRemotes:WaitForChild("PlaySound")
local rev_droppedTool : RemoteEvent = gunRemotes:WaitForChild("DroppedTool")
local rev_shoot : RemoteEvent = gunRemotes:WaitForChild("Shoot")
local rev_reload : RemoteEvent = gunRemotes:WaitForChild("Reload")

rev_playSound.OnServerEvent:Connect(function(player: Player, soundObject : Sound, delayCorrection : number, soundParent : BasePart)
    playSound(soundObject, soundParent, delayCorrection)
end)

rev_shoot.OnServerEvent:Connect(function(player : Player)
    --draw raycast for visuals, but hit detection will be done on the client
end)

rev_reload.OnServerEvent:Connect(function(player : Player)

end)

rev_droppedTool.OnServerEvent:Connect(function(player: Player, tool : Tool)
    tool.Parent = game.Workspace
    detectDroppedToolHitFloor(tool)
end)