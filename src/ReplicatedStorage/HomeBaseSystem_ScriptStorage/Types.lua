--!strict
--[[
	Shared type definitions for the home-base ↔ wasteland gameplay loop.
	See docs/HOME_BASE_LOOP_RESEARCH.md for the design these types encode.

	One server is multiplayer: each player has a private instanced bunker (safe zone) and all
	players travel independently into ONE shared, persistent wasteland (emergent PvP/co-op).
	Base access is modeled as a permission check so cross-base visiting can be added later.
]]

-- A single persisted item: catalog name + stack size + a whitelisted attribute bag
-- (e.g. a gun's ammo, a stackable's Quantity). Rehydrated by cloning the ToolCatalog entry.
export type StoredItem = {
	tag: string, -- ToolCatalog key (tool name)
	quantity: number,
	attributes: { [string]: any },
}

-- Persisted base progression. `type` selects the HomeBaseConfig template (Bunker now,
-- Spaceship later); `upgrades`/`builds` are open-ended tables the upgrade system defines.
export type BaseData = {
	type: string,
	upgrades: { [string]: any },
	builds: { [string]: any },
}

-- The whole per-player persisted profile (one session-locked DataStore key per player).
-- Replaces the current one-DataStore-per-stat design and folds in inventory + base state.
export type ProfileData = {
	stats: { [string]: number }, -- Caps, LightBullets, ... (migrated from legacy attributes)
	storage: { StoredItem }, -- what's banked in the base
	base: BaseData,
}

-- Where a player is in the core loop. Server-owned; gates which actions are legal.
export type LoopState = "InBunker" | "TravelingOut" | "InWasteland" | "TravelingHome"

-- Runtime handle for an allocated base region (not persisted).
export type BaseRegion = {
	owner: Player,
	origin: CFrame, -- world anchor the template was cloned to
	model: Model, -- the cloned base template instance
	entryCFrame: CFrame, -- where an entering player is placed
}

-- Type-only module: returns an empty table so `require` yields a value cleanly.
return {}
