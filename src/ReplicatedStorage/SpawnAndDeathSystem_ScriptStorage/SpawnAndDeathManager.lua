--[[
Code in here is currently just to store code from other modules that should've been separated into a separate module here
]]

local RunService = game:GetService("RunService")


local SpawnAndDeathManager = {}
	--SPAWNS
local spawnPointsFolder = workspace:FindFirstChild("spawnPoints", true):: Folder
SpawnAndDeathManager.spawns = {
	spawn0 = spawnPointsFolder:WaitForChild("spawn0")
}

function SpawnAndDeathManager.applyCharacterProtocolTitleScreen(character)
	if not RunService:IsServer() then
		error("This function is not supposed to be called on the client")
	end
	local ff = Instance.new("ForceField")
	ff.Parent = character
    task.spawn(function()
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.Anchored = true
    end)
end

function SpawnAndDeathManager.cleanUpCharacterProtocolTitleScreen(character: Model)
	if not RunService:IsServer() then
		error("This function is not supposed to be called on the client")
	end
	local ff = character:FindFirstChildOfClass("ForceField")
	if ff then
		ff:Destroy()	
	end
    task.spawn(function()
        local hrp = character:WaitForChild("HumanoidRootPart")
        hrp.Anchored = false
    end)
end

return SpawnAndDeathManager