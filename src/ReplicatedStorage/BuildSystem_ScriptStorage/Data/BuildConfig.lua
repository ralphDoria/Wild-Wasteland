--!strict
--[[
	All building numbers in one version-controlled, shape-tested place (same rationale as
	VitalsConfig/CombatStats). Read by the client preview (BuildModeManager) and the server
	authority (BuildSystem_Server/BuildService) — so both sides always agree.

	`panelSize` is THE knob: the structure piece is one 8x8x0.1 union (placeholder until the
	real union lands in ReplicatedStorage.BuildSystem_Assets.StructurePanel), and the grid
	cell size derives from its face dimension. Resize the union → update panelSize → the
	whole grid follows. BuildConfig.spec pins the derivation.
]]

export type StructureStats = {
	maxHealth: number,
}

export type BuildConfig = {
	-- Dimensions of the structure panel (X/Y = the square face, Z = thickness).
	panelSize: Vector3,
	-- Grid cell edge length, derived from the panel face. Never set independently.
	cellSize: number,
	structures: { [string]: StructureStats },
	-- Seconds for a placed structure to ramp from spawn health to maxHealth (Fortnite-style:
	-- the piece exists and collides immediately, it's just weak and translucent while building).
	buildTime: number,
	-- Fraction of maxHealth a structure has the instant it is placed.
	spawnHealthFraction: number,
	-- How far (studs) the placement ray reaches / the server allows a slot from the builder.
	maxBuildRange: number,
	-- Extra server-side range slack: the client measures camera→hit while the server measures
	-- character-pivot→slot-CENTER, which can legitimately differ by up to ~a cell diagonal.
	rangeSlack: number,
	-- Min seconds between honored placements per player (server rate limit + client debounce).
	placementCooldown: number,
	-- Construction-ramp update cadence (one Heartbeat accumulator, VitalsService pattern).
	rampTickInterval: number,
	-- |cell index| bound accepted from the wire (keeps slots inside sane world coordinates).
	maxCellIndex: number,
	-- Client preview ghost appearance.
	previewColor: Color3,
	previewTransparency: number,
	-- Transparency a structure spawns with; eases to 0 as the build completes.
	constructionStartTransparency: number,
	-- The real union goes in ReplicatedStorage[assetsFolderName][templateName]; until it
	-- exists the server generates a plain Part of panelSize. Either way the server parents
	-- the canonical template into the runtime storage folder so the client ghost clones
	-- the exact same instance.
	assetsFolderName: string,
	templateName: string,
	storageFolderName: string,
}

local panelSize = Vector3.new(8, 8, 0.1)

local BuildConfig: BuildConfig = {
	panelSize = panelSize,
	cellSize = panelSize.X,
	structures = {
		Wall = { maxHealth = 150 },
		Floor = { maxHealth = 140 },
		Stairs = { maxHealth = 140 },
	},
	buildTime = 5,
	spawnHealthFraction = 0.1,
	maxBuildRange = 40,
	rangeSlack = panelSize.X * 1.75,
	placementCooldown = 0.15,
	rampTickInterval = 0.1,
	maxCellIndex = 5000,
	previewColor = Color3.fromRGB(70, 130, 255),
	previewTransparency = 0.6,
	constructionStartTransparency = 0.5,
	assetsFolderName = "BuildSystem_Assets",
	templateName = "StructurePanel",
	storageFolderName = "BuildSystem_Storage",
}

return BuildConfig
