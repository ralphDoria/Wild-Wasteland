--!nonstrict
--[[
	Session-locked per-player profile persistence — the critical-path replacement for the
	one-DataStore-per-stat design (Miscellaneous/DataSaveSystem). ONE profile key per player
	holds { stats, storage, base } (see docs/HOME_BASE_LOOP_RESEARCH.md). Also satisfies BUGS.md
	M15 (full retry / session locking).

	This is a THIN ADAPTER over ProfileStore (lm-loleris/profilestore) — the battle-tested
	session-locking / auto-save / graceful-migration module — so the rest of the system codes
	against the small stable interface below and never touches ProfileStore directly. Swapping
	the backing store later means editing only this file.

	ProfileStore gives us for free: cross-server session hand-off (StartSessionAsync notifies the
	owning server to make a final save before releasing), periodic auto-save, :Reconcile() to
	fill new template fields on existing saves, and OnSessionEnd for lock-loss handling.

	LEGACY STAT MIGRATION (wired here):
	- On a profile's FIRST load, `migrateLegacyStats` imports each legacy per-stat DataStore
	  (the ones DataSaveSystem writes, named per PlayerStatsInfo) into Profile.Data.stats, then
	  stamps `migratedLegacyStats = true` so it never re-imports. Legacy stores are read-only here
	  and left intact.
	- `bindStatSync` then SHADOWS the live stat attributes into Profile.Data on every change. The
	  existing game mutates stats via `player:SetAttribute(...)` directly (CapsAndAmmoPickUp etc.),
	  so the profile mirrors those writes and its auto-save / final-save always hold current values.
	- Deliberately, this does NOT set the stat attributes itself — DataSaveSystem is still the live
	  authority, and we don't want two systems racing PlayerAdded to write attributes. The profile
	  is a complete, always-current SHADOW, ready to become authoritative.

	REMAINING SWITCH (not done here): flip authority to the profile — retire DataSaveSystem's
	load/save connections and have `load` apply Data->attributes + set StatsLoaded. One deliberate
	change once this shadow has been validated in the live game.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local HomeBaseConfig = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.Data.HomeBaseConfig)
local PlayerStatsInfo = require(ReplicatedStorage.RojoManaged_RS.Utility.PlayerStatsInfo)

-- Template = the default profile shape. ProfileStore:Reconcile() backfills these onto older
-- saves, so adding a field here is a safe, non-destructive migration.
local PROFILE_TEMPLATE = {
	stats = {},
	storage = {},
	base = {
		type = HomeBaseConfig.defaultBaseType,
		upgrades = {},
		builds = {},
	},
	migratedLegacyStats = false, -- flipped true once the one-time legacy import has run
}

local playerStore = ProfileStore.New(HomeBaseConfig.profile.storeName, PROFILE_TEMPLATE)

-- Legacy per-stat DataStore handles — the exact stores DataSaveSystem reads/writes (one DataStore
-- named after each stat, keyed by UserId). Built once; used read-only for the one-time import.
local legacyStatStores: { [string]: DataStore } = {}
for _, stat in PlayerStatsInfo.getAll() do
	legacyStatStores[stat.name] = DataStoreService:GetDataStore(stat.name)
end

local PlayerProfileService = {}

-- player -> ProfileStore profile object (nil when no active session)
local profiles: { [Player]: any } = {}
-- player -> stat-attribute shadow connections (disconnected on release / session end)
local statSyncConnections: { [Player]: { RBXScriptConnection } } = {}

-- ── Legacy stat migration ────────────────────────────────────────────────────────────────────

-- One-time import of the legacy per-stat DataStores into Profile.Data.stats. Idempotent via the
-- `migratedLegacyStats` flag. Legacy reads are pcall'd (and no-op in Studio without API access).
local function migrateLegacyStats(player: Player, data: any)
	if data.migratedLegacyStats then
		return
	end
	for _, stat in PlayerStatsInfo.getAll() do
		local name = stat.name
		if data.stats[name] == nil then
			local ok, value = pcall(function()
				return legacyStatStores[name]:GetAsync(player.UserId)
			end)
			if ok and typeof(value) == "number" then
				data.stats[name] = value
			end
		end
	end
	data.migratedLegacyStats = true
end

-- Ensure every known stat exists in Data (default 0) and mirror live attribute writes into Data,
-- so ProfileStore's auto-save / final-save always persist the current values.
local function bindStatSync(player: Player, data: any)
	local conns = {}
	for _, stat in PlayerStatsInfo.getAll() do
		local name = stat.name
		if data.stats[name] == nil then
			data.stats[name] = 0
		end
		table.insert(
			conns,
			player:GetAttributeChangedSignal(name):Connect(function()
				local value = player:GetAttribute(name)
				if typeof(value) == "number" then
					data.stats[name] = value
				end
			end)
		)
	end
	statSyncConnections[player] = conns
end

local function cleanupPlayer(player: Player)
	local conns = statSyncConnections[player]
	if conns then
		for _, c in conns do
			c:Disconnect()
		end
		statSyncConnections[player] = nil
	end
	profiles[player] = nil
end

-- ── Public interface (stable; the whole system depends only on these) ────────────────────────

-- Start (session-lock) a player's profile. Yields. Returns the live Profile.Data table, or nil
-- on failure / if the player left mid-load (caller should stop and let PlayerRemoving clean up).
function PlayerProfileService.load(player: Player): any?
	local profile = playerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players -- stop trying if they already left
		end,
	})

	if not profile then
		return nil -- could not acquire the session (another server won't release / DataStore down)
	end

	profile:AddUserId(player.UserId) -- GDPR compliance / association
	profile:Reconcile() -- backfill any new PROFILE_TEMPLATE fields onto older saves

	profile.OnSessionEnd:Connect(function()
		-- The session was lost (another server stole it, or the store dropped it). Drop our
		-- reference + shadow connections and kick so we never write stale data over the new owner's.
		cleanupPlayer(player)
		player:Kick("Your profile session was ended remotely. Please rejoin.")
	end)

	if player.Parent ~= Players then
		-- Player left during the async load; release immediately so their data isn't locked.
		profile:EndSession()
		return nil
	end

	profiles[player] = profile

	-- Legacy migration: one-time import of the old per-stat DataStores, then keep Data mirrored to
	-- the live stat attributes so auto-save / final-save always persist current values.
	migrateLegacyStats(player, profile.Data)
	bindStatSync(player, profile.Data)

	return profile.Data
end

-- Get the already-loaded live data table (nil if not loaded / already released).
function PlayerProfileService.get(player: Player): any?
	local profile = profiles[player]
	return if profile then profile.Data else nil
end

-- Whether a live session is held (data is safe to mutate).
function PlayerProfileService.isLoaded(player: Player): boolean
	return profiles[player] ~= nil
end

-- End the session (save + release lock). ProfileStore makes the final save itself. Disconnecting
-- the stat shadow first is safe — EndSession's final save reads the already-mirrored Data.
function PlayerProfileService.release(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	cleanupPlayer(player)
	profile:EndSession()
end

-- ProfileStore auto-saves; explicit shutdown flushing is handled by ProfileStore's own
-- game:BindToClose. Kept for interface symmetry / callers that want an eager release.
function PlayerProfileService.releaseAll()
	for _, player in Players:GetPlayers() do
		PlayerProfileService.release(player)
	end
end

-- ── Stats convenience (keeps the attribute-based API the rest of the game already reads) ──────
-- Mirrors a stat into both the profile and a player attribute so existing GetAttribute readers
-- keep working while persistence moves under this service.
function PlayerProfileService.setStat(player: Player, statName: string, value: number)
	local data = PlayerProfileService.get(player)
	if not data then
		return
	end
	data.stats[statName] = value
	player:SetAttribute(statName, value)
end

function PlayerProfileService.getStat(player: Player, statName: string): number?
	local data = PlayerProfileService.get(player)
	return if data then data.stats[statName] else nil
end

return PlayerProfileService
