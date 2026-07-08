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

	TODO(migration): first load for an existing player should import the legacy per-stat
	DataStores (PlayerStatsInfo) into Profile.Data.stats, after which this becomes the sole
	writer and DataSaveSystem.server.lua is retired. Left as a follow-up; the two coexist for now.
]]

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local HomeBaseConfig = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.Data.HomeBaseConfig)

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
}

local playerStore = ProfileStore.New(HomeBaseConfig.profile.storeName, PROFILE_TEMPLATE)

local PlayerProfileService = {}

-- player -> ProfileStore profile object (nil when no active session)
local profiles: { [Player]: any } = {}

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
		-- reference and kick so we never write stale data over the new owner's.
		profiles[player] = nil
		player:Kick("Your profile session was ended remotely. Please rejoin.")
	end)

	if player.Parent ~= Players then
		-- Player left during the async load; release immediately so their data isn't locked.
		profile:EndSession()
		return nil
	end

	profiles[player] = profile
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

-- End the session (save + release lock). ProfileStore makes the final save itself.
function PlayerProfileService.release(player: Player)
	local profile = profiles[player]
	if not profile then
		return
	end
	profiles[player] = nil
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
