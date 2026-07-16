--!strict
--[[
	All building numbers in one version-controlled, shape-tested place (same rationale as
	VitalsConfig/CombatStats). Read by the client preview (BuildModeManager) and the server
	authority (BuildSystem_Server/BuildService) — so both sides always agree.

	`panelSize` is THE knob: the structure piece is the RustyMetalSheet union at
	ReplicatedStorage.BuildSystem_Storage (place-built), and the grid cell size derives
	from its square face. The union's thin axis can be any of X/Y/Z — BuildMath detects it
	from panelSize — so replacing or resizing the piece only means updating panelSize here.
	BuildConfig.spec pins the derivation.
]]

export type StructureStats = {
	maxHealth: number,
}

export type BuildConfig = {
	-- Dimensions of the structure panel. Two equal components form the square face; the
	-- smallest is the thickness (RustyMetalSheet is Y-thin: 8 x 0.205 x 8).
	panelSize: Vector3,
	-- Grid cell edge length, derived from the panel face. Never set independently.
	cellSize: number,
	structures: { [string]: StructureStats },
	-- Seconds for a placed structure to ramp from spawn health to maxHealth (Fortnite-style:
	-- the piece exists and collides immediately, it's just weak and translucent while building).
	buildTime: number,
	-- Fraction of maxHealth a structure has the instant it is placed.
	spawnHealthFraction: number,
	-- Length of the client aim ray. Selection is then CLAMPED into the build region, so
	-- this only decides how far away a surface can steer the preview.
	maxBuildRange: number,
	-- Build region half-extent in cells around the cell containing the character's
	-- HumanoidRootPart: 1 = the Fortnite-style 3x3x3 neighborhood.
	buildRegionRadiusCells: number,
	-- A placement must TOUCH something (map geometry, terrain, or another structure):
	-- the contact probe expands the piece's box by this many studs on every side.
	groundContactMargin: number,
	-- Min seconds between honored placements per player (server rate limit + client debounce).
	placementCooldown: number,
	-- Construction-ramp update cadence (one Heartbeat accumulator, VitalsService pattern).
	rampTickInterval: number,
	-- |cell index| bound accepted from the wire (keeps slots inside sane world coordinates).
	maxCellIndex: number,
	-- Client preview ghost appearance (valid slot / invalid slot = occupied or floating).
	previewColor: Color3,
	previewInvalidColor: Color3,
	previewTransparency: number,
	-- Transparency a structure spawns with; eases to 0 as the build completes.
	constructionStartTransparency: number,
	-- The panel piece lives at ReplicatedStorage[storageFolderName][templateName]
	-- (place-built union; the server generates a panelSize placeholder Part there if
	-- it's ever missing, so the system still runs in a fresh place).
	storageFolderName: string,
	templateName: string,
	-- Runtime workspace folder holding every placed structure (server-created; the
	-- client watches it to preview occupancy).
	placedFolderName: string,
}

local panelSize = Vector3.new(8, 0.205, 8)

local BuildConfig: BuildConfig = {
	panelSize = panelSize,
	cellSize = math.max(panelSize.X, panelSize.Y, panelSize.Z),
	structures = {
		Wall = { maxHealth = 150 },
		Floor = { maxHealth = 140 },
		Stairs = { maxHealth = 140 },
	},
	buildTime = 5,
	spawnHealthFraction = 0.1,
	maxBuildRange = 40,
	buildRegionRadiusCells = 1,
	groundContactMargin = 0.5,
	placementCooldown = 0.15,
	rampTickInterval = 0.1,
	maxCellIndex = 5000,
	previewColor = Color3.fromRGB(70, 130, 255),
	previewInvalidColor = Color3.fromRGB(235, 70, 60),
	previewTransparency = 0.6,
	constructionStartTransparency = 0.5,
	storageFolderName = "BuildSystem_Storage",
	templateName = "RustyMetalSheet",
	placedFolderName = "PlacedStructures",
}

return BuildConfig
