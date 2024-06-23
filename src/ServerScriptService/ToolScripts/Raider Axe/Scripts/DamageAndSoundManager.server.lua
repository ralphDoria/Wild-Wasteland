--Contains sanity checks & handles giving out damage

------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local tool = script.Parent.Parent

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
------------------------------------------------------------------------<<<REMOTE & BINDABLE EVENTS>>>
local Events = tool:WaitForChild("Events")
local RemoteEvents = Events:WaitForChild("RemoteEvents")
local rev_Hit = RemoteEvents:WaitForChild("Hit")
local rev_playSound = RemoteEvents:WaitForChild("PlaySound")
	
--config
local config = require(tool:WaitForChild("Scripts"):WaitForChild("config"))

--SFX
local SFX_part = tool:WaitForChild("SFX_part")
local hitSound = SFX_part:WaitForChild("Sword Hit (Impact)")

rev_Hit.OnServerEvent:Connect(function(player : Player, humanoid : Humanoid, hitLocation)
	if humanoid.Health > 0 then
		playSound(hitSound, 0.2, SFX_part)
		humanoid:TakeDamage(config.damage)
	end
	local damagedPlayerName : string = humanoid.Parent.Name
	--print(damagedPlayerName .. " was hit in their " .. hitLocation.Name)
end)

rev_playSound.OnServerEvent:Connect(function(player : Player, sound : Sound, delayCorrection : number, soundParent : BasePart)
	playSound(sound, delayCorrection, soundParent)
end)

