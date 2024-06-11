--Contains sanity checks & handles giving out damage

local tool = script.Parent.Parent
local RemoteEvents = tool:WaitForChild("Events"):WaitForChild("RemoteEvents")
local rev_Hit = RemoteEvents:WaitForChild("Hit")
local DebrisService = game:GetService("Debris")

--config
local config = require(tool:WaitForChild("Scripts"):WaitForChild("config"))

--SFX
local SFX_part = tool:WaitForChild("SFX_part")
local hitSound = SFX_part:WaitForChild("Sword Hit (Impact)")

local function playSound(soundObject : Sound, delayCorrection : number)
	local soundClone = soundObject:Clone()
	if delayCorrection then
		soundClone.TimePosition = delayCorrection
	end
	soundClone.Parent = hitSound.Parent
	soundClone:Play()
	DebrisService:AddItem(soundClone, soundClone.TimeLength)
end

rev_Hit.OnServerEvent:Connect(function(player : Player, humanoid : Humanoid, hitLocation)
	if humanoid.Health > 0 then
		playSound(hitSound, 0.2)
		humanoid:TakeDamage(config.damage)
	end
	local damagedPlayerName : string = humanoid.Parent.Name
	--print(damagedPlayerName .. " was hit in their " .. hitLocation.Name)
end)

