--Contains sanity checks & handles giving out damage

------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local tool = script.Parent.Parent
local damage = 25
local blood = game:GetService("ServerStorage"):WaitForChild("VFX"):WaitForChild("Blood") 
local damageIndicator = game:GetService("ServerStorage"):WaitForChild("VFX"):WaitForChild("damageIndicator") 

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris") 
local TweenService = game:GetService("TweenService")

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
------------------------------------------------------------------------<<<REMOTE & BINDABLE EVENTS>>>
local Events = tool:WaitForChild("Events")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local rev_Hit = RemoteEvents:WaitForChild("Hit")
local rev_playSound = RemoteEvents:WaitForChild("PlaySound")

--SFX
local SFX_part = tool:WaitForChild("SFX_part")
local hitSound = SFX_part:WaitForChild("Sword Hit (Impact)")

local tInfo = TweenInfo.new(0.1, Enum.EasingStyle.Exponential, Enum.EasingDirection.In)

rev_Hit.OnServerEvent:Connect(function(player : Player, humanoid : Humanoid, hitLocationCFrame : CFrame)
	if humanoid.Health > 0 then
		playSound(hitSound, 0.2, SFX_part)
		humanoid:TakeDamage(damage)
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

rev_playSound.OnServerEvent:Connect(function(player : Player, sound : Sound, delayCorrection : number, soundParent : BasePart)
	playSound(sound, delayCorrection, soundParent)
end)

