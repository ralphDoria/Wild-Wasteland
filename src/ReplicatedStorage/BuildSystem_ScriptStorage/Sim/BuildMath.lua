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

type BuildConfigLike = {
	cellSize: number,
	panelSize: Vector3,
	maxCellIndex: number,
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

--[[
	Snap an aim point (plus the camera yaw, for oriented kinds) to the slot it selects.
	The caller should nudge the aim point slightly toward the camera before calling
	(~0.1 studs) so a ray that lands ON an existing surface snaps to the near side of it.
	Assumes kind is valid — the client only ever passes its own three names; the server
	entry point is validateSlot, not this.
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

-- Center of the slot's panel (server range checks; cheaper than the full CFrame).
function BuildMath.slotCenter(config: BuildConfigLike, slot: Slot): Vector3
	return slotPosition(config, slot)
end

--[[
	World CFrame for the slot's panel. The panel's native axes: X and Y are the square
	face, Z is the thin axis.
	- Wall orient 0 turns the thin axis onto world X; orient 1 keeps it on Z.
	- Floor pitches the panel flat (thin axis vertical).
	- Stairs yaw to their ascent direction, then pitch 45 degrees; with the stretched
	  slotSize the panel's long axis exactly bridges the cell's bottom edge to the
	  opposite top edge.
]]
function BuildMath.slotToCFrame(config: BuildConfigLike, slot: Slot): CFrame
	local position = slotPosition(config, slot)
	if slot.kind == "Wall" then
		if slot.orient == 0 then
			return CFrame.new(position) * CFrame.Angles(0, HALF_PI, 0)
		end
		return CFrame.new(position)
	elseif slot.kind == "Floor" then
		return CFrame.new(position) * CFrame.Angles(HALF_PI, 0, 0)
	end
	return CFrame.new(position) * CFrame.Angles(0, slot.orient * HALF_PI, 0) * CFrame.Angles(math.rad(45), 0, 0)
end

-- Physical size of the placed panel. Walls/floors are the raw panel; stairs stretch the
-- long (Y) axis to the cell diagonal so the 45-degree ramp spans the full cell.
function BuildMath.slotSize(config: BuildConfigLike, slot: Slot): Vector3
	if slot.kind == "Stairs" then
		return Vector3.new(config.cellSize, config.cellSize * math.sqrt(2), config.panelSize.Z)
	end
	return config.panelSize
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
