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

local function modifyBloodDecalTransparency(tool : Tool, newTransparency : number)
	local toolModel = tool.ToolModel
	for _, part in toolModel:GetChildren() do
		local decal = part:FindFirstChildOfClass("Decal")
		if decal and decal.Transparency ~= newTransparency then
			for _, eachDecal in part:GetChildren() do
				eachDecal.Transparency = newTransparency
			end
		end
	end
end

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

--[[
	VectorFroce approach to applying knockback, but there are two problems. (1) It's delayed & (2) I need to find out how to convert the 
	forceDirection to the object space of the attachment which the VectorForce is attached to.
]]
local function applyKnockback(part : BasePart, forceDirection : Vector3, forceMagnitude : number)
	local vf = Instance.new("VectorForce")
	local attachment = Instance.new("Attachment")
	vf.Enabled = false
	attachment.Parent = part
	vf.Parent = part
	vf.Attachment0 = attachment
	attachment.CFrame = CFrame.new()
	forceDirection = CFrame.new(forceDirection):ToObjectSpace(attachment.CFrame).Position
	vf.Force = forceDirection * forceMagnitude
	vf.Enabled = true
	Debris:AddItem(vf, 5)
	Debris:AddItem(attachment, 5)
	task.spawn(function()
		task.wait(1)
		vf.Enabled = false
	end)
end

rev_hit.OnServerEvent:Connect(function(player : Player, tool : Tool, humanoid : Humanoid, hitSound : Sound, hitLocationCFrame : CFrame)
	if humanoid then
		if humanoid.Health > 0 then
			playSound(hitSound, 0.2, hitSound.Parent)

			--knockback
			local kbForce = 1_000
			local enemyHrp = humanoid.Parent:WaitForChild("HumanoidRootPart")
			local playerHrp = player.Character:WaitForChild("HumanoidRootPart")
			local isOneShot = humanoid.Health <= tonumber(tool:GetAttribute("Damage"))
			if not isOneShot then
				--applyKnockback(enemyHrp, playerHrp.CFrame.LookVector, 5_000	)
				enemyHrp:ApplyImpulse(playerHrp.CFrame.LookVector * kbForce)
			else
				--applyKnockback(enemyHrp, playerHrp.CFrame.LookVector, 200)
				enemyHrp:ApplyImpulse(playerHrp.CFrame.LookVector * (kbForce * 0.5))
			end

			humanoid:TakeDamage(tool:GetAttribute("Damage"))
			--modifyBloodDecalTransparency(tool, 0)   | this works but there are inconsistencies with the view model that I don't feel like doing right now, so I'm temporarily disabling it 
		end
		-- put this on the client
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
	end
end)

rev_droppedTool.OnServerEvent:Connect(function(player: Player, tool : Tool)
    tool.Parent = game.Workspace
    detectDroppedToolHitFloor(tool)
end)