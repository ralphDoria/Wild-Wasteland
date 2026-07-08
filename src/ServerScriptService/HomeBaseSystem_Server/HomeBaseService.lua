--!nonstrict
--[[
	Creates and owns each player's private bunker. On join: allocate a grid region, clone the
	configured base template into it, rehydrate banked storage + build state from the profile,
	and expose the entry CFrame the player spawns/returns to. On leave: snapshot and free it.

	Access is a PERMISSION CHECK, never "one region belongs to one player physically" — so a
	future feature where players visit each other's bases only needs `canEnter` to say yes. The
	safe-zone and storage rules elsewhere must likewise be written as "is this player allowed /
	does this player own this storage", not "is this player the region owner".

	SCAFFOLD STATUS: region math + template-clone flow are real; they depend on place content
	that does not exist yet (ServerStorage.HomeBaseTemplates.<templateName> and the named anchor
	parts inside it — see HomeBaseConfig). Missing content degrades to a warn + nil region, never
	a crash. Storage rehydrate/snapshot is wired to ItemSerializer but the physical storage UI/
	container is BaseStorageService's job.
]]

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HomeBaseConfig = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.Data.HomeBaseConfig)
local PlayerProfileService = require(script.Parent.PlayerProfileService)

local HomeBaseService = {}

-- owner Player -> BaseRegion handle
local regions: { [Player]: any } = {}
-- monotonic cell index so each allocated base gets a distinct grid cell
local nextCellIndex = 0

-- ── Region allocation ────────────────────────────────────────────────────────────────────────

local function cellOrigin(index: number): CFrame
	local cfg = HomeBaseConfig.region
	local col = index % cfg.columns
	local row = math.floor(index / cfg.columns)
	local pos = cfg.origin + Vector3.new(col * cfg.cellSpacing.X, 0, row * cfg.cellSpacing.Z)
	return CFrame.new(pos)
end

local function getTemplate(baseType: string): Model?
	local templatesFolder = ServerStorage:FindFirstChild("HomeBaseTemplates")
	if not templatesFolder then
		warn("[HomeBaseService] ServerStorage.HomeBaseTemplates folder is missing (place content)")
		return nil
	end
	local cfg = HomeBaseConfig.baseTypes[baseType]
	if not cfg then
		warn(`[HomeBaseService] unknown base type '{baseType}'`)
		return nil
	end
	local template = templatesFolder:FindFirstChild(cfg.templateName)
	if not template or not template:IsA("Model") then
		warn(`[HomeBaseService] template '{cfg.templateName}' missing or not a Model`)
		return nil
	end
	return template
end

-- ── Public interface ──────────────────────────────────────────────────────────────────────────

-- Build (or return the existing) base region for a player. Requires the profile to be loaded.
-- Returns the BaseRegion handle, or nil if place content is missing.
function HomeBaseService.createBaseFor(player: Player): any?
	if regions[player] then
		return regions[player]
	end
	local profile = PlayerProfileService.get(player)
	if not profile then
		warn(`[HomeBaseService] no loaded profile for {player.Name}; cannot create base`)
		return nil
	end
	local baseType = profile.base.type or HomeBaseConfig.defaultBaseType
	local template = getTemplate(baseType)
	if not template then
		return nil
	end
	local cfg = HomeBaseConfig.baseTypes[baseType]

	local origin = cellOrigin(nextCellIndex)
	nextCellIndex += 1

	local model = template:Clone()
	model:PivotTo(origin)
	model.Parent = workspace -- TODO: a dedicated ServerStorage-backed folder / StreamingEnabled tuning

	local region = {
		owner = player,
		origin = origin,
		model = model,
		entryCFrame = origin * cfg.entryOffset,
	}
	regions[player] = region

	-- TODO(rehydrate): reconstruct persisted builds/upgrades onto `model`, and hand
	-- profile.storage to BaseStorageService to populate the storage container.
	HomeBaseService.rehydrateBuilds(player, region)

	return region
end

function HomeBaseService.getRegion(player: Player): any?
	return regions[player]
end

-- Where should this player enter their base (spawn on join, and land on return-home travel).
function HomeBaseService.getEntryCFrame(player: Player): CFrame?
	local region = regions[player]
	return if region then region.entryCFrame else nil
end

-- Permission gate for entering a base. Today: owner only. Designed so cross-base visiting is a
-- one-line policy change here (e.g. friends, or an "open base" flag) with nothing else touched.
function HomeBaseService.canEnter(visitor: Player, baseOwner: Player): boolean
	return visitor == baseOwner
end

-- SCAFFOLD: reconstruct persisted structures/upgrades into the cloned model. No-op until the
-- build system + template contract exist.
function HomeBaseService.rehydrateBuilds(_player: Player, _region: any)
	-- TODO
end

-- Snapshot the live base back into the profile (called before save / on leave). BaseStorage owns
-- the storage list; this captures build/upgrade state from the model.
function HomeBaseService.snapshot(player: Player)
	local region = regions[player]
	local profile = PlayerProfileService.get(player)
	if not region or not profile then
		return
	end
	-- TODO(snapshot): read placed builds/upgrades off region.model into profile.base.
end

-- Free the region (on leave). Snapshots first so nothing is lost.
function HomeBaseService.releaseBaseFor(player: Player)
	local region = regions[player]
	if not region then
		return
	end
	HomeBaseService.snapshot(player)
	if region.model then
		region.model:Destroy()
	end
	regions[player] = nil
end

return HomeBaseService
