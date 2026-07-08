--!strict
--[[
	Version-controlled, shape-testable config for the home-base loop — every number and every
	place-content reference lives here (mirrors VitalsConfig / CombatStats / ConsumableStats).

	IMPORTANT: the `templateName`/part-name fields below name instances that must exist in the
	Studio place (ServerStorage / workspace). They are NOT created by this repo. Keep them in
	sync with the place; a missing one degrades to a warn at region-allocation time, not a hard
	crash (see HomeBaseService). Listed in one place so the place-content contract is explicit.
]]

export type BaseTypeConfig = {
	templateName: string, -- Model under ServerStorage.HomeBaseTemplates to clone
	entryOffset: CFrame, -- where to place an entering player, relative to the region origin
	storageAnchorName: string, -- name of the Part in the template marking the storage access point
	safeZoneName: string, -- name of the Part in the template defining the safe-zone volume
}

local HomeBaseConfig = {}

-- ── Base types (Bunker now; add Spaceship etc. by dropping a new template + entry here) ──────
HomeBaseConfig.defaultBaseType = "Bunker"

HomeBaseConfig.baseTypes = {
	Bunker = {
		templateName = "BunkerTemplate",
		entryOffset = CFrame.new(0, 5, 0),
		storageAnchorName = "StorageAnchor",
		safeZoneName = "SafeZone",
	},
} :: { [string]: BaseTypeConfig }

-- ── Region allocation (single-place: each player's base gets its own grid cell far apart) ────
-- Bases are laid out on a grid well below/away from the playable map so they never overlap the
-- shared wasteland. Origin + spacing are deliberately large; tune once the templates exist.
HomeBaseConfig.region = {
	origin = Vector3.new(0, -5000, 0), -- first cell's world position
	cellSpacing = Vector3.new(500, 0, 500), -- gap between adjacent cells
	columns = 16, -- cells per row before wrapping to the next row
}

-- ── Shared wasteland (ONE persistent area every player travels into) ─────────────────────────
HomeBaseConfig.wasteland = {
	arrivalPartName = "WastelandArrival", -- Part in workspace marking where travelers appear
	-- returnPartName is per-base (the base's entryCFrame), not global.
}

-- ── Travel intermission timing (seconds) ─────────────────────────────────────────────────────
HomeBaseConfig.travel = {
	toWastelandSeconds = 5,
	toHomeSeconds = 5,
}

-- ── Persistence ──────────────────────────────────────────────────────────────────────────────
HomeBaseConfig.profile = {
	storeName = "PlayerProfile_v1", -- bump the suffix to migrate to a new schema
	sessionLockStaleSeconds = 30, -- a lock older than this is considered abandoned (crash) and stealable
	loadRetries = 5,
}

-- ── Item-attribute whitelist per tool Type (what serialize/deserialize persists) ─────────────
-- Only these attributes survive a store→retrieve round-trip; everything else is presentation.
-- Keyed by the tool's `Type` attribute (see ToolCatalog). Unknown types fall back to `default`.
HomeBaseConfig.attributeWhitelist = {
	default = { "Quantity" },
	Stackable = { "Quantity" },
	Gun = { "Quantity", "Ammo", "AmmoReserve" },
} :: { [string]: { string } }

return HomeBaseConfig
