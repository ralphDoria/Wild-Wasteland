local Debris = game:GetService("Debris") 
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local blood = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("VFX"):WaitForChild("Blood") 
local damageIndicator = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("VFX"):WaitForChild("damageIndicator") 

local detectDroppedToolHitFloor = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("DetectDroppedToolHitFloor"))
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

local remotes : Folder = ReplicatedStorage:WaitForChild("Tools"):WaitForChild("Melee"):WaitForChild("Remotes")
local rev_playSound : RemoteEvent = remotes:WaitForChild("PlaySound")
local rev_droppedTool : RemoteEvent = remotes:WaitForChild("DroppedTool")
local rev_hit : RemoteEvent = remotes:WaitForChild("Hit")
local rev_activate : RemoteEvent = remotes:WaitForChild("Activate")

rev_playSound.OnServerEvent:Connect(function(player: Player, soundObject : Sound, delayCorrection : number, soundParent : BasePart)
    playSound(soundObject, delayCorrection, soundParent)
end)

rev_activate.OnServerEvent:Connect(function(player: Player, tool : Tool, isActivated : boolean, soundObject : Sound, delayCorrection : number, soundParent : BasePart)
    local trail : Trail = tool.Hitbox.Trail
    if isActivated then
        trail.Enabled = true
        playSound(soundObject, delayCorrection, soundParent)
    else
        trail.Enabled = false
    end
end)

rev_hit.OnServerEvent:Connect(function(player : Player, tool : Tool, humanoid : Humanoid, hitSound : Sound, hitLocationCFrame : CFrame)
    --[[ This commented out block is for debugging because sometime the humanoid is nil for some reason
	print("humanoid name: " .. humanoid.Name)
	print("humanoid's parent's name: " .. humanoid.Parent.Name)
	]]
	if humanoid.Health > 0 then
		playSound(hitSound, 0.2, hitSound.Parent)
		humanoid:TakeDamage(tool:GetAttribute("Damage"))
	end
	--
		local character = humanoid.Parent
		local x = blood:Clone()
		x.CFrame = hitLocationCFrame
		x.Parent = workspace
		task.wait(0.1)
		x.ParticleEmitter.Enabled = false
		Debris:AddItem(x, 0.5)
		local d = damageIndicator:Clone()
		d.BillboardGui.TextLabel.Text = tostring(humanoid.Health)
		d.Parent = character
		d.Anchored = false
		local weld = Instance.new("Weld")
		weld.Part0 = character.Head
		weld.Part1 = d
		weld.Name = d.Name
		weld.Parent = character
		local slideUp = TweenService:Create(
			weld, 
			TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), 
			{C0 = CFrame.new(0, 2, 0)}
		)
		local fadeOut = TweenService:Create(
			d.BillboardGui.TextLabel, 
			TweenInfo.new(1, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), 
			{TextTransparency = 1}
		)
		slideUp:Play()
		fadeOut:Play()
	--
end)

rev_droppedTool.OnServerEvent:Connect(function(player: Player, tool : Tool)
    tool.Parent = game.Workspace
    detectDroppedToolHitFloor(tool)
end)