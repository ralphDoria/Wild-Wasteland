--!nonstrict
--[[
	Deposit/withdraw between a player's inventory and their base storage. Storage is SERVER
	state (the authoritative list lives in profile.storage); the client only ever sees a pushed
	view via the StorageChanged remote and requests mutations — same discipline as the Stackable
	and Looting receivers. Every request is validated through the shared Validation boundary.

	Ownership is a PERMISSION CHECK (HomeBaseService.canEnter + "does this player own this
	storage"), not "is this the region owner", so visiting-another-base later needs no rework.

	SCAFFOLD STATUS: deposit/withdraw flow, validation gating, and the serialize/deserialize
	calls are wired; the physical storage container (where withdrawn tools are placed, and how
	the storage-access proximity is gated to players near their StorageAnchor) is left as TODO
	because it depends on the base template content.
]]

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Validation = require(
	ServerScriptService.RojoManaged_SSS.ItemSystem_Server.Revamp.Receivers.Validation
)
local ItemSerializer = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.ItemSerializer)
local HomeBaseConfig = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.Data.HomeBaseConfig)
local PlayerProfileService = require(script.Parent.PlayerProfileService)

-- Server-side spawn path (clone-from-catalog) used to rehydrate withdrawn items.
local ServerSpawnTool = ReplicatedStorage:WaitForChild("ItemSystem_Storage").Shared.Bindables.ServerSpawnTool :: BindableFunction
local function spawnTool(toolName: string, parent: Instance): Instance?
	return ServerSpawnTool:Invoke(toolName, parent)
end

local BaseStorageService = {}
local remotes: { [string]: RemoteEvent }? = nil

-- Push the authoritative storage list to the owning client.
local function pushStorage(player: Player)
	local profile = PlayerProfileService.get(player)
	if remotes and profile then
		remotes.StorageChanged:FireClient(player, profile.storage)
	end
end

-- Deposit a carried tool the sender owns into their base storage.
local function deposit(player: Player, tool: any)
	if not Validation.isInstance(tool, "Tool") then return end
	if not Validation.ownsTool(player, tool) then return end
	local profile = PlayerProfileService.get(player)
	if not profile then return end
	-- TODO(gate): require the player to be InBunker and near their StorageAnchor before allowing.

	local entry = ItemSerializer.serialize(tool, HomeBaseConfig.attributeWhitelist)
	table.insert(profile.storage, entry)
	tool:Destroy() -- consumed from the world; it now lives as data
	pushStorage(player)
end

-- Withdraw a stored item (by index into profile.storage) back into the player's backpack.
local function withdraw(player: Player, storageIndex: any)
	if not Validation.isInteger(storageIndex, 1) then return end
	local profile = PlayerProfileService.get(player)
	if not profile then return end
	local entry = profile.storage[storageIndex]
	if not entry then return end
	-- TODO(gate): require InBunker + near StorageAnchor; check backpack space.

	local tool = ItemSerializer.deserialize(entry, spawnTool, player.Backpack)
	if not tool then
		return -- catalog miss / malformed; leave the entry in storage rather than lose it
	end
	table.remove(profile.storage, storageIndex)
	pushStorage(player)
end

-- Populate storage view on base creation (profile already rehydrated by HomeBaseService).
function BaseStorageService.onBaseReady(player: Player)
	pushStorage(player)
end

function BaseStorageService.init(remoteMap: { [string]: RemoteEvent })
	remotes = remoteMap
	remoteMap.RequestDeposit.OnServerEvent:Connect(deposit)
	remoteMap.RequestWithdraw.OnServerEvent:Connect(withdraw)
end

return BaseStorageService
