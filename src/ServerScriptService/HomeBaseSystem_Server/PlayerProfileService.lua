--!nonstrict
--[[
	Session-locked per-player profile persistence — the critical-path replacement for the
	current one-DataStore-per-stat design (Miscellaneous/DataSaveSystem). ONE DataStore key per
	player holds { stats, storage, base } (see HomeBaseConfig.profile.storeName and
	docs/HOME_BASE_LOOP_RESEARCH.md). This is also where BUGS.md M15's "full retry / session
	locking is Tier 3" note gets satisfied.

	SCAFFOLD STATUS: the load/save/release flow and the UpdateAsync-based session lock are
	sketched with the correct shape, but the locking is deliberately conservative and NOT yet
	hardened/playtested. Two paths forward, decide before relying on it:
	  (a) finish this hand-rolled UpdateAsync lock (steal-after-stale, release on remove), or
	  (b) adopt the community ProfileStore module (recommended — battle-tested session locking)
	      as a Wally dependency and make this a thin adapter over it.
	Either way the PUBLIC INTERFACE below is what the rest of the system codes against, so the
	choice stays isolated here.

	TODO(migration): first load for an existing player should import the legacy per-stat
	DataStores (PlayerStatsInfo) into profile.stats, then this service becomes the sole writer
	and DataSaveSystem.server.lua is retired. Not done yet — the two coexist during scaffolding.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HomeBaseConfig = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.Data.HomeBaseConfig)

local store = DataStoreService:GetDataStore(HomeBaseConfig.profile.storeName)

local PlayerProfileService = {}

-- In-memory live profiles for players on this server. The rest of the system reads/mutates
-- these; they are flushed to the DataStore on release.
local profiles: { [Player]: any } = {}

local function defaultProfile()
	return {
		stats = {},
		storage = {},
		base = {
			type = HomeBaseConfig.defaultBaseType,
			upgrades = {},
			builds = {},
		},
		-- lock metadata (server jobId + timestamp) is written into the DataStore, not exposed here
	}
end

-- ── Public interface (stable; the whole system depends only on these) ────────────────────────

-- Load (and session-lock) a player's profile. Yields. Returns the live profile table, or nil
-- on hard failure (caller should then kick the player to avoid data loss).
function PlayerProfileService.load(player: Player): any?
	-- TODO(lock): UpdateAsync that (1) reads existing data, (2) refuses if a fresh lock from
	-- another server is present, (3) steals a lock older than sessionLockStaleSeconds, (4)
	-- stamps our jobId + os.time(), (5) returns the data. Retry loadRetries times.
	local data
	for attempt = 1, HomeBaseConfig.profile.loadRetries do
		local ok, result = pcall(function()
			return store:GetAsync(player.UserId) -- PLACEHOLDER: replace with the UpdateAsync lock above
		end)
		if ok then
			data = result or defaultProfile()
			break
		end
		warn(`[PlayerProfileService] load attempt {attempt} failed for {player.Name}: {tostring(result)}`)
		task.wait(2 ^ attempt) -- exponential backoff
	end
	if not data then
		return nil
	end
	profiles[player] = data
	return data
end

-- Get the already-loaded live profile (nil if not loaded / already released).
function PlayerProfileService.get(player: Player): any?
	return profiles[player]
end

-- Persist the live profile without releasing the lock (periodic autosave / pre-travel checkpoint).
function PlayerProfileService.save(player: Player): boolean
	local data = profiles[player]
	if not data then
		return false
	end
	local ok, err = pcall(function()
		-- TODO(lock): UpdateAsync that verifies WE still hold the lock before writing.
		store:SetAsync(player.UserId, data) -- PLACEHOLDER
	end)
	if not ok then
		warn(`[PlayerProfileService] save failed for {player.Name}: {tostring(err)}`)
	end
	return ok
end

-- Save and drop the session lock (on PlayerRemoving / BindToClose).
function PlayerProfileService.release(player: Player)
	PlayerProfileService.save(player)
	-- TODO(lock): clear the lock stamp so another server can take over immediately.
	profiles[player] = nil
end

-- Flush every live profile (server shutdown). Bounded so we never hang shutdown.
function PlayerProfileService.releaseAll()
	local remaining = 0
	for player in profiles do
		remaining += 1
		task.spawn(function()
			PlayerProfileService.release(player)
			remaining -= 1
		end)
	end
	local elapsed = 0
	while remaining > 0 and elapsed < 25 do
		elapsed += task.wait()
	end
end

-- Convenience for the stats leg (keeps the attribute-based API the rest of the game expects).
-- Mirrors a stat into both the profile and a player attribute so existing readers keep working.
function PlayerProfileService.setStat(player: Player, statName: string, value: number)
	local data = profiles[player]
	if not data then
		return
	end
	data.stats[statName] = value
	player:SetAttribute(statName, value)
end

function PlayerProfileService.getStat(player: Player, statName: string): number?
	local data = profiles[player]
	return if data then data.stats[statName] else nil
end

return PlayerProfileService
