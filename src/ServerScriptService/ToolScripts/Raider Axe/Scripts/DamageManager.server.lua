--Containts sanity checks & handles giving out damage

local tool = script.Parent.Parent
local RemoteEvents = tool:WaitForChild("Events"):WaitForChild("RemoteEvents")
local rev_Hit = RemoteEvents:WaitForChild("Hit")

--config
local config = require(tool:WaitForChild("Scripts"):WaitForChild("config"))

--SFX
local SFX_part = tool:WaitForChild("SFX_part")
local hitSound = SFX_part:WaitForChild("Sword Hit (Impact)")

rev_Hit.OnServerEvent:Connect(function(player : Player, humanoid : Humanoid, hitLocation)
	hitSound:Play()
	humanoid:TakeDamage(config.damage)
	local damagedPlayerName : string = humanoid.Parent.Name
	--print(damagedPlayerName .. " was hit in their " .. hitLocation.Name)
end)

