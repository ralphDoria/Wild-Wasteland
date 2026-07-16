--!strict
--[[
	Pure grid math — no Roblox services, no state (VitalsSim/XPCurve pattern). The client
	preview and the server authority run these exact functions, so the ghost the player sees
	and the structure the server spawns can't disagree; TestEZ pins every branch
	(tests/specs/BuildMath.spec.lua).

	Grid model (c = config.cellSize, derived from the panel face):
	- The world is cubic cells [x, x+1) x [y, y+1) x [z, z+1) in cell units, anchored at the
	  world origin.
	- WALL  {kind, x, y, z, orient 0|1}: a panel on a cell-BOUNDARY plane. orient 0 is
	  perpendicular to world X at X = x*c; orient 1 perpendicular to Z at Z = z*c. Every
	  boundary plane has exactly one integer triple + orient, so the two cells sharing a
	  face map to the SAME slot — occupancy dedup needs no neighbor logic.
	- FLOOR {kind, x, y, z, orient = 0}: a horizontal panel at Y = y*c spanning cell (x, z).
	  Shared between vertically adjacent cells by the same construction.
	- STAIRS {kind, x, y, z, orient 0..3}: a ramp through the VOLUME of cell (x, y, z),
	  ascending in the orient direction (0=+Z, 1=+X, 2=-Z, 3=-X). The panel is stretched to
	  c*sqrt(2) along its long axis so the 45-degree tilt spans the full cell: bottom edge on
	  the cell's bottom boundary, top edge on the opposite top boundary
	  (c*sqrt(2) * cos(45) == c both vertically and horizontally).

	Build region (Fortnite-style): slots are only selectable/placeable in the cube of
	cells buildRegionRadiusCells around the cell containing the builder's
	HumanoidRootPart (radius 1 = the 3x3x3 neighborhood). A boundary-panel slot (wall/
	floor) is in-region when a cell it borders is; a stairs slot when its cell is. The
	client SELECTS by ray-march (selectSlotAlongRay: every in-region slot the aim ray
	passes through, closest-to-builder wins), the server verifies with isSlotInRegion.

	Panel orientation: geometry is computed in a canonical frame (local X/Y = the square
	face, Z = the thin axis) and then corrected for the real panel piece, whose thin axis
	is DETECTED from config.panelSize (the RustyMetalSheet union is Y-thin) — so swapping
	or re-orienting the piece only means updating panelSize.

	The wire format is the five scalars (kind, x, y, z, orient) — never a CFrame. The server
	re-derives all geometry through validateSlot/slotToCFrame, so a client can only ever
	request "a legal slot", not "a position".
]]

local BuildMath = {}

export type Slot = {
	kind: string,
	x: number,
	y: number,
	z: number,
	orient: number,
}

export type Cell = {
	x: number,
	y: number,
	z: number,
}

type BuildConfigLike = {
	cellSize: number,
	panelSize: Vector3,
	maxCellIndex: number,
	buildRegionRadiusCells: number,
	structures: { [string]: any },
}

local HALF_PI = math.pi / 2

-- Max orient (inclusive) per structure kind; also the kind whitelist.
local MAX_ORIENT = {
	Wall = 1,
	Floor = 0,
	Stairs = 3,
}

-- A finite whole number within +/- bound. Written out (rather than reusing the server's
-- Validation module) so BuildMath stays pure and requireable from both sides; NaN fails
-- the self-equality check, +/-inf fails the bounds.
local function isBoundedInt(value: any, bound: number): boolean
	return typeof(value) == "number"
		and value == value
		and value >= -bound
		and value <= bound
		and value % 1 == 0
end

--[[
	Correction from the real panel's local axes to the canonical frame (X/Y face,
	Z thin), keyed on which panelSize component is smallest. Returns the rotation R
	(so a slot's world CFrame is canonicalCFrame * R) and a size mapper taking
	canonical extents (faceA, faceB/long, thickness) to the part's local Size.
]]
local function panelBasis(config: BuildConfigLike): (CFrame, (number, number, number) -> Vector3)
	local s = config.panelSize
	if s.Z <= s.X and s.Z <= s.Y then
		-- Z-thin: already canonical.
		return CFrame.identity, function(a: number, b: number, t: number)
			return Vector3.new(a, b, t)
		end
	elseif s.Y <= s.X and s.Y <= s.Z then
		-- Y-thin (RustyMetalSheet): part Y -> canonical Z, part Z -> canonical -Y.
		return CFrame.Angles(HALF_PI, 0, 0), function(a: number, b: number, t: number)
			return Vector3.new(a, t, b)
		end
	end
	-- X-thin: part X -> canonical Z, part Z -> canonical -X.
	return CFrame.Angles(0, -HALF_PI, 0), function(a: number, b: number, t: number)
		return Vector3.new(t, b, a)
	end
end

local function panelThickness(config: BuildConfigLike): number
	local s = config.panelSize
	return math.min(s.X, s.Y, s.Z)
end

-- Snap a yaw (radians, Roblox convention: 0 looks toward -Z) to its nearest 90-degree
-- quadrant index 0..3. Quadrant q means the camera looks toward (-sin(q*90), -cos(q*90)).
function BuildMath.yawToOrient(yaw: number): number
	return math.round(yaw / HALF_PI) % 4
end

-- The direction a look-quadrant's STAIRS ascend so that the ramp rises away from the
-- builder: ascent(orient) is (+Z, +X, -Z, -X) for orient 0..3, and the quadrant's look
-- vector is the opposite of quadrant 0's ascent, hence the half-turn.
local function lookQuadrantToStairsOrient(quadrant: number): number
	return (quadrant + 2) % 4
end

-- Walls face the builder: looking along +/-Z wants a plane perpendicular to Z (orient 1),
-- looking along +/-X wants perpendicular to X (orient 0).
local function lookQuadrantToWallOrient(quadrant: number): number
	return 1 - quadrant % 2
end

-- Ties in the closest-to-builder comparison (studs): within this, the candidate hit
-- EARLIER along the ray wins, per the selection rule.
local DISTANCE_TIE_EPSILON = 1e-3

-- Plane crossings only: a panel sitting ON the surface that stopped the ray (a built
-- wall's own grid plane) must still count as crossed despite the hit landing a hair in
-- front of it. Deliberately NOT applied to stairs cell entries — a cell that starts
-- exactly at a blocked boundary is on the far side of whatever blocked it.
local PLANE_CROSSING_SLACK = 0.25

--[[
	Snap an aim point (plus the camera yaw, for oriented kinds) to the slot it selects.
	The caller should nudge the aim point slightly toward the camera before calling
	(~0.1 studs) so a ray that lands ON an existing surface snaps to the near side of it,
	then clamp the result into the build region with clampSlotToRegion. Assumes kind is
	valid — the client only ever passes its own three names; the server entry point is
	validateSlot, not this.
]]
function BuildMath.worldToSlot(config: BuildConfigLike, kind: string, aimPoint: Vector3, cameraYaw: number): Slot
	local c = config.cellSize
	local px, py, pz = aimPoint.X / c, aimPoint.Y / c, aimPoint.Z / c
	local quadrant = BuildMath.yawToOrient(cameraYaw)

	if kind == "Floor" then
		return { kind = kind, x = math.floor(px), y = math.round(py), z = math.floor(pz), orient = 0 }
	elseif kind == "Wall" then
		local orient = lookQuadrantToWallOrient(quadrant)
		if orient == 0 then
			-- Plane perpendicular to X: X snaps to the nearest boundary, the rest to cells.
			return { kind = kind, x = math.round(px), y = math.floor(py), z = math.floor(pz), orient = 0 }
		end
		return { kind = kind, x = math.floor(px), y = math.floor(py), z = math.round(pz), orient = 1 }
	elseif kind == "Stairs" then
		return {
			kind = kind,
			x = math.floor(px),
			y = math.floor(py),
			z = math.floor(pz),
			orient = lookQuadrantToStairsOrient(quadrant),
		}
	end
	error(`[BuildMath] Unknown structure kind "{kind}"`)
end

-- The cell containing a world point (used with the character's HumanoidRootPart to
-- anchor the build region).
function BuildMath.cellOfPoint(config: BuildConfigLike, point: Vector3): Cell
	local c = config.cellSize
	return {
		x = math.floor(point.X / c),
		y = math.floor(point.Y / c),
		z = math.floor(point.Z / c),
	}
end

--[[
	Clamp a slot into the build region around a center cell (the client's "always
	preview near you" behavior). Boundary panels are in-region when EITHER cell they
	border is a region cell, hence the +1 on the boundary-plane axis; the panel's span
	axes clamp to region cells directly. Orientation is never changed.
]]
function BuildMath.clampSlotToRegion(config: BuildConfigLike, slot: Slot, center: Cell): Slot
	local r = config.buildRegionRadiusCells
	local xLo, xHi = center.x - r, center.x + r
	local yLo, yHi = center.y - r, center.y + r
	local zLo, zHi = center.z - r, center.z + r

	local x, y, z
	if slot.kind == "Wall" and slot.orient == 0 then
		x = math.clamp(slot.x, xLo, xHi + 1) -- boundary planes bounding region cells
		y = math.clamp(slot.y, yLo, yHi)
		z = math.clamp(slot.z, zLo, zHi)
	elseif slot.kind == "Wall" then
		x = math.clamp(slot.x, xLo, xHi)
		y = math.clamp(slot.y, yLo, yHi)
		z = math.clamp(slot.z, zLo, zHi + 1)
	elseif slot.kind == "Floor" then
		x = math.clamp(slot.x, xLo, xHi)
		y = math.clamp(slot.y, yLo, yHi + 1)
		z = math.clamp(slot.z, zLo, zHi)
	else -- Stairs occupy a region cell outright
		x = math.clamp(slot.x, xLo, xHi)
		y = math.clamp(slot.y, yLo, yHi)
		z = math.clamp(slot.z, zLo, zHi)
	end
	return { kind = slot.kind, x = x, y = y, z = z, orient = slot.orient }
end

-- Server-side region gate: a slot is in-region iff clamping wouldn't move it.
function BuildMath.isSlotInRegion(config: BuildConfigLike, slot: Slot, center: Cell): boolean
	local clamped = BuildMath.clampSlotToRegion(config, slot, center)
	return clamped.x == slot.x and clamped.y == slot.y and clamped.z == slot.z
end

-- Occupancy key. Stairs deliberately EXCLUDE orient: two stairs in one cell always
-- overlap, so any rotation claims the whole cell. Wall keys include orient because the
-- two boundary planes through one corner triple are different physical slots.
function BuildMath.slotKey(slot: Slot): string
	if slot.kind == "Wall" then
		return `W:{slot.x}:{slot.y}:{slot.z}:{slot.orient}`
	elseif slot.kind == "Floor" then
		return `F:{slot.x}:{slot.y}:{slot.z}`
	end
	return `S:{slot.x}:{slot.y}:{slot.z}`
end

local function slotPosition(config: BuildConfigLike, slot: Slot): Vector3
	local c = config.cellSize
	if slot.kind == "Wall" then
		if slot.orient == 0 then
			return Vector3.new(slot.x * c, (slot.y + 0.5) * c, (slot.z + 0.5) * c)
		end
		return Vector3.new((slot.x + 0.5) * c, (slot.y + 0.5) * c, slot.z * c)
	elseif slot.kind == "Floor" then
		return Vector3.new((slot.x + 0.5) * c, slot.y * c, (slot.z + 0.5) * c)
	end
	return Vector3.new((slot.x + 0.5) * c, (slot.y + 0.5) * c, (slot.z + 0.5) * c)
end

-- Center of the slot's panel (server range/region anchoring; cheaper than the full CFrame).
function BuildMath.slotCenter(config: BuildConfigLike, slot: Slot): Vector3
	return slotPosition(config, slot)
end

--[[
	World CFrame for the slot's panel, in the real piece's axes (canonical placement *
	panel-basis correction).
	- Wall orient 0 turns the thin axis onto world X; orient 1 keeps it on Z.
	- Floor pitches the panel flat (thin axis vertical).
	- Stairs yaw to their ascent direction, then pitch 45 degrees; with the stretched
	  slotSize the panel's long axis exactly bridges the cell's bottom edge to the
	  opposite top edge.
]]
function BuildMath.slotToCFrame(config: BuildConfigLike, slot: Slot): CFrame
	local correction = panelBasis(config)
	local position = slotPosition(config, slot)
	local canonical: CFrame
	if slot.kind == "Wall" then
		if slot.orient == 0 then
			canonical = CFrame.new(position) * CFrame.Angles(0, HALF_PI, 0)
		else
			canonical = CFrame.new(position)
		end
	elseif slot.kind == "Floor" then
		canonical = CFrame.new(position) * CFrame.Angles(HALF_PI, 0, 0)
	else
		canonical = CFrame.new(position)
			* CFrame.Angles(0, slot.orient * HALF_PI, 0)
			* CFrame.Angles(math.rad(45), 0, 0)
	end
	return canonical * correction
end

-- Physical Size of the placed panel in the real piece's axes. Walls/floors are the
-- face-sized panel; stairs stretch the long axis to the cell diagonal so the 45-degree
-- ramp spans the full cell.
function BuildMath.slotSize(config: BuildConfigLike, slot: Slot): Vector3
	local _, mapSize = panelBasis(config)
	local face = config.cellSize
	local thickness = panelThickness(config)
	if slot.kind == "Stairs" then
		return mapSize(face, face * math.sqrt(2), thickness)
	end
	return mapSize(face, face, thickness)
end

-- Slab test: parameter t at which a ray enters an axis-aligned box, or nil if the ray
-- misses it within [0, maxDistance]. Starting inside the box counts as entry at 0.
local function rayBoxEntry(origin: Vector3, direction: Vector3, maxDistance: number, minCorner: Vector3, maxCorner: Vector3): number?
	local tEnter, tExit = 0, maxDistance
	local function slab(o: number, d: number, lo: number, hi: number): boolean
		if math.abs(d) < 1e-9 then
			return o >= lo and o <= hi
		end
		local t1, t2 = (lo - o) / d, (hi - o) / d
		if t1 > t2 then
			t1, t2 = t2, t1
		end
		tEnter = math.max(tEnter, t1)
		tExit = math.min(tExit, t2)
		return tEnter <= tExit
	end
	if
		slab(origin.X, direction.X, minCorner.X, maxCorner.X)
		and slab(origin.Y, direction.Y, minCorner.Y, maxCorner.Y)
		and slab(origin.Z, direction.Z, minCorner.Z, maxCorner.Z)
	then
		return tEnter
	end
	return nil
end

--[[
	THE selection rule (client preview): enumerate every in-region slot of the kind that
	the aim ray passes through — wall/floor slots where the ray crosses their grid
	plane, stairs slots for each region cell the ray's segment enters — with the ray
	capped at maxDistance (the caller stops it at the first solid hit: built structures,
	map geometry, and terrain all block; nothing past the hit is ever a candidate).
	FLOORS additionally offer both planes bounding the aim point's (region-clamped)
	cell, so ground sitting between grid planes stays selectable and a level aim still
	has a feet-plane option.

	Returns the full candidate list ordered CLOSEST-first by panel-center distance to
	anchorPoint (the caller passes the HumanoidRootPart — biased down to the feet for
	floors), ties broken by which was crossed earlier along the ray, duplicates
	dropped. The caller walks it for the first VALID slot (occupancy/support are the
	caller's concern — not modeled here) and falls back to entry 1 when none qualify.

	Never empty: aiming somewhere with no reachable slot at all (e.g. straight up at
	the sky with a wall) degrades to the snapped ray end clamped into the region, so
	there is always a slot to preview and the ghost never disappears.
]]
function BuildMath.slotCandidatesAlongRay(
	config: BuildConfigLike,
	kind: string,
	origin: Vector3,
	direction: Vector3, -- unit length
	maxDistance: number,
	center: Cell,
	cameraYaw: number,
	anchorPoint: Vector3
): { Slot }
	local c = config.cellSize
	local r = config.buildRegionRadiusCells
	local quadrant = BuildMath.yawToOrient(cameraYaw)
	local candidates: { { slot: Slot, t: number, distance: number } } = {}

	local function addCandidate(slot: Slot, t: number)
		if BuildMath.isSlotInRegion(config, slot, center) then
			table.insert(candidates, {
				slot = slot,
				t = t,
				distance = (BuildMath.slotCenter(config, slot) - anchorPoint).Magnitude,
			})
		end
	end

	-- Crossings of the ray with one family of grid planes (indices loPlane..hiPlane on
	-- one axis); makeSlot turns each crossing point into the panel slot it selects.
	local function addPlaneCrossings(
		axisOrigin: number,
		axisDirection: number,
		loPlane: number,
		hiPlane: number,
		makeSlot: (planeIndex: number, point: Vector3) -> Slot
	)
		if math.abs(axisDirection) < 1e-6 then
			return -- ray parallel to the family
		end
		for planeIndex = loPlane, hiPlane do
			local t = (planeIndex * c - axisOrigin) / axisDirection
			if t >= 0 and t <= maxDistance + PLANE_CROSSING_SLACK then
				addCandidate(makeSlot(planeIndex, origin + direction * t), t)
			end
		end
	end

	if kind == "Wall" then
		if lookQuadrantToWallOrient(quadrant) == 0 then
			addPlaneCrossings(origin.X, direction.X, center.x - r, center.x + r + 1, function(planeIndex, point)
				return { kind = kind, x = planeIndex, y = math.floor(point.Y / c), z = math.floor(point.Z / c), orient = 0 }
			end)
		else
			addPlaneCrossings(origin.Z, direction.Z, center.z - r, center.z + r + 1, function(planeIndex, point)
				return { kind = kind, x = math.floor(point.X / c), y = math.floor(point.Y / c), z = planeIndex, orient = 1 }
			end)
		end
	elseif kind == "Floor" then
		addPlaneCrossings(origin.Y, direction.Y, center.y - r, center.y + r + 1, function(planeIndex, point)
			return { kind = kind, x = math.floor(point.X / c), y = planeIndex, z = math.floor(point.Z / c), orient = 0 }
		end)
	elseif kind == "Stairs" then
		local orient = lookQuadrantToStairsOrient(quadrant)
		-- The region is tiny (27 cells at radius 1): slab-test each cell's box against
		-- the ray segment instead of a general voxel walk.
		for x = center.x - r, center.x + r do
			for y = center.y - r, center.y + r do
				for z = center.z - r, center.z + r do
					local t = rayBoxEntry(
						origin,
						direction,
						maxDistance,
						Vector3.new(x * c, y * c, z * c),
						Vector3.new((x + 1) * c, (y + 1) * c, (z + 1) * c)
					)
					if t then
						addCandidate({ kind = kind, x = x, y = y, z = z, orient = orient }, t)
					end
				end
			end
		end
	end

	-- Terminal candidates at the nudged ray end (per kind — the snap must never reach
	-- PAST the surface that stopped the ray):
	-- - Floors: BOTH planes bounding the aim point's cell, clamped into the region
	--   (ground between grid planes stays selectable; the feet-biased anchor then
	--   prefers the plane underfoot). Vertical-only snap — can't tunnel a wall.
	-- - Walls: NONE. worldToSlot ROUNDS the facing axis, which can jump up to half a
	--   cell beyond the hit surface; the crossing enumeration already covers every
	--   wall plane actually reached.
	-- - Stairs: NONE needed — the cell traversal already includes the (in-region)
	--   cell the ray ends in.
	local terminalPoint = origin + direction * math.max(maxDistance - 0.1, 0)
	if kind == "Floor" then
		local cellX = math.clamp(math.floor(terminalPoint.X / c), center.x - r, center.x + r)
		local cellY = math.clamp(math.floor(terminalPoint.Y / c), center.y - r, center.y + r)
		local cellZ = math.clamp(math.floor(terminalPoint.Z / c), center.z - r, center.z + r)
		addCandidate({ kind = kind, x = cellX, y = cellY, z = cellZ, orient = 0 }, maxDistance)
		addCandidate({ kind = kind, x = cellX, y = cellY + 1, z = cellZ, orient = 0 }, maxDistance)
	end

	if #candidates == 0 then
		return { BuildMath.clampSlotToRegion(config, BuildMath.worldToSlot(config, kind, terminalPoint, cameraYaw), center) }
	end

	-- Order closest-first by repeated min-extraction (the list is tiny — a handful of
	-- planes/cells) so the tie rule stays exact: within DISTANCE_TIE_EPSILON, the
	-- candidate crossed EARLIER along the ray comes first. Duplicate slots (a terminal
	-- plane that was also a crossing) keep only their best-ranked occurrence.
	local ordered: { Slot } = {}
	local seenKeys: { [string]: boolean } = {}
	while #candidates > 0 do
		local bestIndex = 1
		for i = 2, #candidates do
			local a, b = candidates[i], candidates[bestIndex]
			if
				a.distance < b.distance - DISTANCE_TIE_EPSILON
				or (math.abs(a.distance - b.distance) <= DISTANCE_TIE_EPSILON and a.t < b.t)
			then
				bestIndex = i
			end
		end
		local best = table.remove(candidates, bestIndex)
		local key = BuildMath.slotKey(best.slot)
		if not seenKeys[key] then
			seenKeys[key] = true
			table.insert(ordered, best.slot)
		end
	end
	return ordered
end

-- The single best candidate (see slotCandidatesAlongRay) — kept as the head of the
-- ordered list for callers/specs that only need the winner.
function BuildMath.selectSlotAlongRay(
	config: BuildConfigLike,
	kind: string,
	origin: Vector3,
	direction: Vector3,
	maxDistance: number,
	center: Cell,
	cameraYaw: number,
	anchorPoint: Vector3
): Slot
	return BuildMath.slotCandidatesAlongRay(config, kind, origin, direction, maxDistance, center, cameraYaw, anchorPoint)[1]
end

--[[
	The server's trust boundary for the wire scalars: whitelisted kind, finite whole
	cell indices within +/- maxCellIndex, orient a whole number in the kind's range.
	Returns a FRESH Slot table (never client-supplied references) or nil.
]]
function BuildMath.validateSlot(config: BuildConfigLike, kind: any, x: any, y: any, z: any, orient: any): Slot?
	if typeof(kind) ~= "string" then
		return nil
	end
	local maxOrient = MAX_ORIENT[kind]
	if maxOrient == nil or config.structures[kind] == nil then
		return nil
	end
	local bound = config.maxCellIndex
	if not (isBoundedInt(x, bound) and isBoundedInt(y, bound) and isBoundedInt(z, bound)) then
		return nil
	end
	if not isBoundedInt(orient, maxOrient) or orient < 0 then
		return nil
	end
	return { kind = kind, x = x, y = y, z = z, orient = orient }
end

return BuildMath
