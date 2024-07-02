local Debris = game:GetService("Debris") 
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local healingLiquidSquirt = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("VFX"):WaitForChild("Blood") 
local damageIndicator = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("VFX"):WaitForChild("damageIndicator") 

local detectDroppedToolHitFloor = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("DetectDroppedToolHitFloor"))
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

local consumableRemotes : Folder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Consumable"):WaitForChild("Remotes")
local rev_playSound : RemoteEvent = consumableRemotes:WaitForChild("PlaySound")
local rev_droppedTool : RemoteEvent = consumableRemotes:WaitForChild("DroppedTool")
local rev_activate : RemoteEvent = consumableRemotes:WaitForChild("Activate")

rev_playSound.OnServerEvent:Connect(function(player: Player, soundObject : Sound, delayCorrection : number, soundParent : BasePart)
    playSound(soundObject, delayCorrection, soundParent)
end)

rev_activate.OnServerEvent:Connect(function(player: Player, tool : Tool)
    local humanoid = player.Character:FindFirstChild("Humanoid")
    print(humanoid.Parent.Name .. " is getting healed")
    humanoid.Health = humanoid.Health + 50
end)

rev_droppedTool.OnServerEvent:Connect(function(player: Player, tool : Tool, dispose : boolean)
    tool.Parent = game.Workspace
    if dispose then
        tool.BodyAttach.PickUpPrompt:Destroy()
        Debris:AddItem(tool, 10)
    end
    detectDroppedToolHitFloor(tool)
end)