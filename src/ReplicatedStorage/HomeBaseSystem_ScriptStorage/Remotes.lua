--!strict
--[[
	Runtime remote registry for the home-base loop. Following the vitals-rewrite philosophy
	(MovementIntent), the whole `HomeBaseSystem_Storage.Remotes` folder is created at RUNTIME
	on the server — nothing needs to be added to the Studio place. The client resolves the same
	folder with WaitForChild.

	Every request remote is server-validated; the server owns all movement and all storage
	mutation (this is also where the C5 client-CFrame teleport exploit dies — clients never send
	a destination, only an intent).

	Remotes:
	  RequestTravel   (RemoteEvent, C→S)  fire("Wasteland" | "Home") — intent only, no CFrame
	  TravelStateChanged (RemoteEvent, S→C) server tells the client its LoopState + intermission time
	  RequestDeposit  (RemoteEvent, C→S)  fire(tool)   — bank a carried item into base storage
	  RequestWithdraw (RemoteEvent, C→S)  fire(storedItemId) — pull a banked item back out
	  StorageChanged  (RemoteEvent, S→C)  server pushes the authoritative storage view
]]

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FOLDER_NAME = "HomeBaseSystem_Storage"
local REMOTE_NAMES = {
	"RequestTravel",
	"TravelStateChanged",
	"RequestDeposit",
	"RequestWithdraw",
	"StorageChanged",
}

local Remotes = {}

-- Server: create the folder + remotes once (idempotent). Returns a name→RemoteEvent map.
function Remotes.initServer(): { [string]: RemoteEvent }
	assert(RunService:IsServer(), "Remotes.initServer must run on the server")
	local storage = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not storage then
		storage = Instance.new("Folder")
		storage.Name = FOLDER_NAME
		storage.Parent = ReplicatedStorage
	end
	local remotesFolder = storage:FindFirstChild("Remotes")
	if not remotesFolder then
		remotesFolder = Instance.new("Folder")
		remotesFolder.Name = "Remotes"
		remotesFolder.Parent = storage
	end
	local map = {}
	for _, name in REMOTE_NAMES do
		local remote = remotesFolder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = remotesFolder
		end
		map[name] = remote
	end
	return map
end

-- Client: wait for the server-created folder and return the same map.
function Remotes.getClient(): { [string]: RemoteEvent }
	local storage = ReplicatedStorage:WaitForChild(FOLDER_NAME)
	local remotesFolder = storage:WaitForChild("Remotes")
	local map = {}
	for _, name in REMOTE_NAMES do
		map[name] = remotesFolder:WaitForChild(name) :: RemoteEvent
	end
	return map
end

return Remotes
