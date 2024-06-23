--Contains sanity checks & handles giving out damage

------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local tool = script.Parent.Parent
local damage = 25
local blood = game:GetService("ServerStorage"):WaitForChild("Particles"):WaitForChild("Blood") 

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris") 

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

rev_Hit.OnServerEvent:Connect(function(player : Player, humanoid : Humanoid, hitLocationCFrame : CFrame)
	if humanoid.Health > 0 then
		playSound(hitSound, 0.2, SFX_part)
		humanoid:TakeDamage(damage)
	end
	--
		local x = blood:Clone()
		x.CFrame = hitLocationCFrame
		x.Parent = workspace
		task.wait(0.1)
		x.ParticleEmitter.Enabled = false
		Debris:AddItem(x, 0.5)
	--
end)

rev_playSound.OnServerEvent:Connect(function(player : Player, sound : Sound, delayCorrection : number, soundParent : BasePart)
	playSound(sound, delayCorrection, soundParent)
end)

