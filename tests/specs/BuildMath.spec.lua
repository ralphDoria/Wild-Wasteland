--!nocheck
--[[
	Pins the pure build-grid math (BuildSystem_ScriptStorage/Sim/BuildMath): snapping,
	the boundary-plane wall dedup guarantee, panel-basis detection (the RustyMetalSheet
	union is Y-thin), stairs geometry spanning the cell, the 3x3x3 build-region clamp,
	occupancy keys, and the validateSlot trust boundary.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildMath = require(ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage.Sim.BuildMath)

-- Small deterministic test config (cell = 8, Y-thin panel like the live piece) so specs
-- don't drift with live tuning.
local config = {
	cellSize = 8,
	panelSize = Vector3.new(8, 0.205, 8),
	maxCellIndex = 100,
	buildRegionRadiusCells = 1,
	structures = { Wall = { maxHealth = 1 }, Floor = { maxHealth = 1 }, Stairs = { maxHealth = 1 } },
}

-- A Z-thin variant proving the panel basis is detected, not assumed.
local zThinConfig = {
	cellSize = 8,
	panelSize = Vector3.new(8, 8, 0.1),
	maxCellIndex = 100,
	buildRegionRadiusCells = 1,
	structures = config.structures,
}

local LOOK_NEG_Z = 0 -- yaw 0 looks toward -Z
local LOOK_NEG_X = math.pi / 2
local LOOK_POS_Z = math.pi
local LOOK_POS_X = -math.pi / 2

local CENTER = { x = 0, y = 0, z = 0 }

local function near(a: number, b: number, eps: number?): boolean
	return math.abs(a - b) <= (eps or 1e-4)
end

return function()
	describe("yawToOrient", function()
		it("maps the four cardinal yaws to quadrants 0..3", function()
			expect(BuildMath.yawToOrient(0)).to.equal(0)
			expect(BuildMath.yawToOrient(math.pi / 2)).to.equal(1)
			expect(BuildMath.yawToOrient(math.pi)).to.equal(2)
			expect(BuildMath.yawToOrient(3 * math.pi / 2)).to.equal(3)
		end)
		it("wraps negative yaws into 0..3", function()
			expect(BuildMath.yawToOrient(-math.pi / 2)).to.equal(3)
			expect(BuildMath.yawToOrient(-math.pi)).to.equal(2)
			expect(BuildMath.yawToOrient(2 * math.pi)).to.equal(0)
		end)
		it("snaps near-quadrant yaws to the nearest quadrant", function()
			expect(BuildMath.yawToOrient(math.rad(10))).to.equal(0)
			expect(BuildMath.yawToOrient(math.rad(80))).to.equal(1)
		end)
	end)

	describe("worldToSlot — Floor", function()
		it("snaps to the containing cell and the nearest horizontal plane", function()
			local slot = BuildMath.worldToSlot(config, "Floor", Vector3.new(12, 7.9, 20), LOOK_NEG_Z)
			expect(slot.x).to.equal(1)
			expect(slot.y).to.equal(1) -- 7.9/8 rounds to plane 1
			expect(slot.z).to.equal(2)
			expect(slot.orient).to.equal(0)
		end)
		it("points just above and just below a plane pick the same plane", function()
			local below = BuildMath.worldToSlot(config, "Floor", Vector3.new(4, 7.9, 4), LOOK_NEG_Z)
			local above = BuildMath.worldToSlot(config, "Floor", Vector3.new(4, 8.1, 4), LOOK_NEG_Z)
			expect(BuildMath.slotKey(below)).to.equal(BuildMath.slotKey(above))
		end)
		it("ignores camera yaw", function()
			local a = BuildMath.worldToSlot(config, "Floor", Vector3.new(4, 0, 4), LOOK_NEG_Z)
			local b = BuildMath.worldToSlot(config, "Floor", Vector3.new(4, 0, 4), LOOK_NEG_X)
			expect(BuildMath.slotKey(a)).to.equal(BuildMath.slotKey(b))
		end)
	end)

	describe("worldToSlot — Wall", function()
		it("looking along Z gives a wall perpendicular to Z (orient 1)", function()
			local slot = BuildMath.worldToSlot(config, "Wall", Vector3.new(4, 4, 8.2), LOOK_NEG_Z)
			expect(slot.orient).to.equal(1)
			expect(slot.z).to.equal(1) -- boundary plane Z = 8
			expect(slot.x).to.equal(0)
			expect(slot.y).to.equal(0)
		end)
		it("looking along X gives a wall perpendicular to X (orient 0)", function()
			local slot = BuildMath.worldToSlot(config, "Wall", Vector3.new(7.8, 4, 4), LOOK_NEG_X)
			expect(slot.orient).to.equal(0)
			expect(slot.x).to.equal(1) -- boundary plane X = 8
		end)
		it("the same boundary approached from either side is ONE slot (dedup guarantee)", function()
			local fromNear = BuildMath.worldToSlot(config, "Wall", Vector3.new(4, 4, 7.9), LOOK_NEG_Z)
			local fromFar = BuildMath.worldToSlot(config, "Wall", Vector3.new(4, 4, 8.1), LOOK_POS_Z)
			expect(BuildMath.slotKey(fromNear)).to.equal(BuildMath.slotKey(fromFar))
		end)
	end)

	describe("worldToSlot — Stairs", function()
		it("occupies the containing cell", function()
			local slot = BuildMath.worldToSlot(config, "Stairs", Vector3.new(12, 9, -3), LOOK_NEG_Z)
			expect(slot.x).to.equal(1)
			expect(slot.y).to.equal(1)
			expect(slot.z).to.equal(-1)
		end)
		it("ascends away from the builder for each cardinal look", function()
			local point = Vector3.new(4, 4, 4)
			-- ascent(orient): 0=+Z, 1=+X, 2=-Z, 3=-X; look -Z must ascend -Z, etc.
			expect(BuildMath.worldToSlot(config, "Stairs", point, LOOK_NEG_Z).orient).to.equal(2)
			expect(BuildMath.worldToSlot(config, "Stairs", point, LOOK_POS_Z).orient).to.equal(0)
			expect(BuildMath.worldToSlot(config, "Stairs", point, LOOK_NEG_X).orient).to.equal(3)
			expect(BuildMath.worldToSlot(config, "Stairs", point, LOOK_POS_X).orient).to.equal(1)
		end)
	end)

	describe("cellOfPoint", function()
		it("returns the containing cell, including negatives", function()
			local cell = BuildMath.cellOfPoint(config, Vector3.new(12, -0.5, 8))
			expect(cell.x).to.equal(1)
			expect(cell.y).to.equal(-1)
			expect(cell.z).to.equal(1)
		end)
	end)

	describe("clampSlotToRegion / isSlotInRegion (radius 1 = 3x3x3)", function()
		it("stairs clamp to the region's cells on every axis", function()
			local slot = { kind = "Stairs", x = 5, y = 0, z = -9, orient = 2 }
			local clamped = BuildMath.clampSlotToRegion(config, slot, CENTER)
			expect(clamped.x).to.equal(1)
			expect(clamped.y).to.equal(0)
			expect(clamped.z).to.equal(-1)
			expect(clamped.orient).to.equal(2) -- orientation never changes
			expect(BuildMath.isSlotInRegion(config, slot, CENTER)).to.equal(false)
			expect(BuildMath.isSlotInRegion(config, clamped, CENTER)).to.equal(true)
		end)
		it("wall boundary planes reach one past the region cells on their normal axis", function()
			-- orient 0 planes bounding cells -1..1 are x = -1..2.
			local farPlane = { kind = "Wall", x = 2, y = 0, z = 0, orient = 0 }
			expect(BuildMath.isSlotInRegion(config, farPlane, CENTER)).to.equal(true)
			local tooFar = { kind = "Wall", x = 3, y = 0, z = 0, orient = 0 }
			expect(BuildMath.isSlotInRegion(config, tooFar, CENTER)).to.equal(false)
			expect(BuildMath.clampSlotToRegion(config, tooFar, CENTER).x).to.equal(2)
			-- but the SPAN axes clamp to region cells directly
			local spanOut = { kind = "Wall", x = 0, y = 4, z = -2, orient = 0 }
			local clamped = BuildMath.clampSlotToRegion(config, spanOut, CENTER)
			expect(clamped.y).to.equal(1)
			expect(clamped.z).to.equal(-1)
		end)
		it("floor planes reach one past the region cells vertically", function()
			expect(BuildMath.isSlotInRegion(config, { kind = "Floor", x = 0, y = 2, z = 0, orient = 0 }, CENTER)).to.equal(true)
			expect(BuildMath.isSlotInRegion(config, { kind = "Floor", x = 0, y = 3, z = 0, orient = 0 }, CENTER)).to.equal(false)
			expect(BuildMath.clampSlotToRegion(config, { kind = "Floor", x = 0, y = 3, z = 0, orient = 0 }, CENTER).y).to.equal(2)
		end)
		it("region follows the center cell", function()
			local center = { x = 10, y = -3, z = 10 }
			expect(BuildMath.isSlotInRegion(config, { kind = "Stairs", x = 9, y = -4, z = 11, orient = 0 }, center)).to.equal(true)
			expect(BuildMath.isSlotInRegion(config, { kind = "Stairs", x = 8, y = -3, z = 10, orient = 0 }, center)).to.equal(false)
		end)
	end)

	describe("selectSlotAlongRay (ray-march selection, closest to the builder wins)", function()
		-- Builder standing in cell (0,0,0): root part at the cell center, eye slightly up.
		local center = { x = 0, y = 0, z = 0 }
		local anchor = Vector3.new(4, 4, 4)
		local eye = Vector3.new(4, 5, 4)
		local FAR = 40

		it("level aim picks the own-cell wall even though the ray crosses farther planes", function()
			local direction = Vector3.new(1, -0.05, 0).Unit -- toward +X
			local slot = BuildMath.selectSlotAlongRay(config, "Wall", eye, direction, FAR, center, LOOK_POS_X, anchor)
			expect(slot.orient).to.equal(0)
			expect(slot.x).to.equal(1) -- your cell's +X face, not the x=2 plane also crossed
			expect(slot.y).to.equal(0)
		end)

		it("aiming up selects the higher wall the ray actually crosses", function()
			local direction = Vector3.new(1, 1.2, 0).Unit
			local slot = BuildMath.selectSlotAlongRay(config, "Wall", Vector3.new(4, 4, 4), direction, FAR, center, LOOK_POS_X, anchor)
			expect(slot.x).to.equal(1)
			expect(slot.y).to.equal(1) -- the crossing point is in the layer above
		end)

		-- Floors anchor at the FEET (HRP - floorSelectionAnchorYOffset), like the manager passes.
		local feetAnchor = Vector3.new(4, 2, 4)

		it("floors: aiming down picks the feet plane, aiming up picks the ceiling", function()
			local down = BuildMath.selectSlotAlongRay(config, "Floor", eye, Vector3.new(1, -1, 0).Unit, FAR, center, LOOK_POS_X, feetAnchor)
			expect(down.y).to.equal(0)
			expect(down.x).to.equal(1) -- the cell the crossing point lands in
			local up = BuildMath.selectSlotAlongRay(config, "Floor", eye, Vector3.new(1, 1, 0).Unit, FAR, center, LOOK_POS_X, feetAnchor)
			expect(up.y).to.equal(1)
			expect(up.x).to.equal(0) -- closest ceiling, not the higher plane also crossed
		end)

		it("floors: a LEVEL aim selects the plane at the feet, never the ceiling", function()
			-- A level ray crosses no horizontal plane; the terminal cell offers both of
			-- its bounding planes and the feet anchor decides.
			local slot = BuildMath.selectSlotAlongRay(config, "Floor", eye, Vector3.new(1, 0, 0), FAR, center, LOOK_POS_X, feetAnchor)
			expect(slot.y).to.equal(0)
		end)

		it("stairs: the own cell (distance 0) beats every farther traversed cell", function()
			local slot = BuildMath.selectSlotAlongRay(config, "Stairs", eye, Vector3.new(1, 0, 0), FAR, center, LOOK_POS_X, anchor)
			expect(slot.x).to.equal(0)
			expect(slot.y).to.equal(0)
			expect(slot.z).to.equal(0)
			expect(slot.orient).to.equal(1) -- look +X ascends +X
		end)

		it("a blocker capping the ray excludes candidates beyond it", function()
			local direction = Vector3.new(1, -0.05, 0).Unit
			local nearAnchor = Vector3.new(13, 4, 4) -- closer to the x=2 plane than x=1
			local unblocked = BuildMath.selectSlotAlongRay(config, "Wall", eye, direction, FAR, center, LOOK_POS_X, nearAnchor)
			expect(unblocked.x).to.equal(2) -- x=2 wins on distance when reachable
			local blocked = BuildMath.selectSlotAlongRay(config, "Wall", eye, direction, 5, center, LOOK_POS_X, nearAnchor)
			expect(blocked.x).to.equal(1) -- ray stopped before the x=2 crossing (t ~ 12)
		end)

		it("walls never snap past the surface that stopped the ray", function()
			-- Blocker at ~8.5 studs, just past the x=8 plane; the x=16 plane is behind
			-- it. Even with an anchor that would prefer the far plane, it must not leak.
			local direction = Vector3.new(1, -0.05, 0).Unit
			local farAnchor = Vector3.new(13, 4, 4)
			local slot = BuildMath.selectSlotAlongRay(config, "Wall", eye, direction, 8.5, center, LOOK_POS_X, farAnchor)
			expect(slot.x).to.equal(1)
		end)

		it("stairs never claim the cell behind a blocked boundary", function()
			-- A wall on the x=8 boundary stops the ray at ~3.9; the far cell's entry is
			-- exactly at the boundary and must be excluded (no slack for cell entries).
			local farAnchor = Vector3.new(14, 4, 4) -- would prefer the far cell if it leaked
			local slot = BuildMath.selectSlotAlongRay(config, "Stairs", eye, Vector3.new(1, 0, 0), 3.9, center, LOOK_POS_X, farAnchor)
			expect(slot.x).to.equal(0)
		end)

		it("an exact distance tie goes to the candidate crossed first", function()
			local direction = Vector3.new(1, -0.05, 0).Unit
			local midAnchor = Vector3.new(12, 4, 4) -- exactly between the x=1 and x=2 panels
			local slot = BuildMath.selectSlotAlongRay(config, "Wall", eye, direction, FAR, center, LOOK_POS_X, midAnchor)
			expect(slot.x).to.equal(1)
		end)

		it("no reachable candidate degrades to a clamped in-region slot (ghost never vanishes)", function()
			-- Straight up: parallel to every wall plane, terminal snap far out of region.
			local slot = BuildMath.selectSlotAlongRay(config, "Wall", eye, Vector3.new(0, 1, 0), FAR, center, LOOK_NEG_Z, anchor)
			expect(BuildMath.isSlotInRegion(config, slot, center)).to.equal(true)
		end)

		it("slotCandidatesAlongRay orders every crossed slot closest-first and dedupes", function()
			local direction = Vector3.new(1, -0.05, 0).Unit -- crosses the x=1 and x=2 planes
			local nearOrder = BuildMath.slotCandidatesAlongRay(config, "Wall", eye, direction, FAR, center, LOOK_POS_X, anchor)
			expect(#nearOrder).to.equal(2)
			expect(nearOrder[1].x).to.equal(1)
			expect(nearOrder[2].x).to.equal(2)
			-- An anchor near the far plane flips the order — same candidates, re-ranked.
			local farOrder = BuildMath.slotCandidatesAlongRay(config, "Wall", eye, direction, FAR, center, LOOK_POS_X, Vector3.new(13, 4, 4))
			expect(#farOrder).to.equal(2)
			expect(farOrder[1].x).to.equal(2)
			expect(farOrder[2].x).to.equal(1)
		end)

		it("slotCandidatesAlongRay is never empty (clamp fallback as the sole entry)", function()
			local list = BuildMath.slotCandidatesAlongRay(config, "Wall", eye, Vector3.new(0, 1, 0), FAR, center, LOOK_NEG_Z, anchor)
			expect(#list).to.equal(1)
			expect(BuildMath.isSlotInRegion(config, list[1], center)).to.equal(true)
		end)

		it("always returns an in-region slot for every kind and direction", function()
			for _, kind in { "Wall", "Floor", "Stairs" } do
				for _, spec in {
					{ dir = Vector3.new(1, -0.3, 0.2).Unit, yaw = LOOK_POS_X },
					{ dir = Vector3.new(0, -1, 0), yaw = LOOK_NEG_Z },
					{ dir = Vector3.new(-0.5, 0.8, -1).Unit, yaw = LOOK_NEG_Z },
				} do
					local slot = BuildMath.selectSlotAlongRay(config, kind, eye, spec.dir, FAR, center, spec.yaw, anchor)
					expect(BuildMath.isSlotInRegion(config, slot, center)).to.equal(true)
				end
			end
		end)
	end)

	describe("slotToCFrame + slotSize geometry (Y-thin panel, like RustyMetalSheet)", function()
		it("wall orient 0 sits ON the X boundary plane with the panel's thin (Y) axis along world X", function()
			local slot = { kind = "Wall", x = 1, y = 0, z = 0, orient = 0 }
			local cf = BuildMath.slotToCFrame(config, slot)
			expect(near(cf.Position.X, 8)).to.equal(true)
			expect(near(cf.Position.Y, 4)).to.equal(true)
			expect(near(cf.Position.Z, 4)).to.equal(true)
			expect(near(math.abs(cf.YVector.X), 1)).to.equal(true)
		end)
		it("floor lies flat with the thin (Y) axis vertical", function()
			local slot = { kind = "Floor", x = 0, y = 1, z = 0, orient = 0 }
			local cf = BuildMath.slotToCFrame(config, slot)
			expect(near(cf.Position.Y, 8)).to.equal(true)
			expect(near(math.abs(cf.YVector.Y), 1)).to.equal(true)
		end)
		it("stairs bottom and top edges land exactly on the cell's edges", function()
			local slot = { kind = "Stairs", x = 0, y = 0, z = 0, orient = 0 } -- ascends +Z
			local cf = BuildMath.slotToCFrame(config, slot)
			local size = BuildMath.slotSize(config, slot)
			-- The long axis is the panel's local Z for a Y-thin piece.
			local endA = cf.Position + cf.ZVector * (size.Z / 2)
			local endB = cf.Position - cf.ZVector * (size.Z / 2)
			local bottom = if endA.Y < endB.Y then endA else endB
			local top = if endA.Y < endB.Y then endB else endA
			expect(near(bottom.Y, 0)).to.equal(true) -- cell bottom
			expect(near(bottom.Z, 0)).to.equal(true) -- near edge
			expect(near(top.Y, 8)).to.equal(true) -- cell top
			expect(near(top.Z, 8)).to.equal(true) -- far edge (ascends +Z)
		end)
		it("sizes map to the piece's axes: stairs stretch local Z, walls/floors keep panelSize", function()
			local stairs = BuildMath.slotSize(config, { kind = "Stairs", x = 0, y = 0, z = 0, orient = 0 })
			expect(near(stairs.Z, 8 * math.sqrt(2))).to.equal(true)
			expect(near(stairs.X, 8)).to.equal(true)
			expect(near(stairs.Y, 0.205)).to.equal(true)
			local wall = BuildMath.slotSize(config, { kind = "Wall", x = 0, y = 0, z = 0, orient = 0 })
			expect(wall).to.equal(config.panelSize)
		end)
	end)

	describe("panel basis detection (Z-thin variant)", function()
		it("a Z-thin panel keeps its thin axis on local Z", function()
			local slot = { kind = "Wall", x = 1, y = 0, z = 0, orient = 0 }
			local cf = BuildMath.slotToCFrame(zThinConfig, slot)
			expect(near(math.abs(cf.ZVector.X), 1)).to.equal(true)
		end)
		it("a Z-thin panel stretches stairs along local Y", function()
			local stairs = BuildMath.slotSize(zThinConfig, { kind = "Stairs", x = 0, y = 0, z = 0, orient = 0 })
			expect(near(stairs.Y, 8 * math.sqrt(2))).to.equal(true)
			expect(near(stairs.Z, 0.1)).to.equal(true)
		end)
	end)

	describe("slotKey", function()
		it("wall keys differ by orient (two planes through one corner are different slots)", function()
			local a = BuildMath.slotKey({ kind = "Wall", x = 1, y = 2, z = 3, orient = 0 })
			local b = BuildMath.slotKey({ kind = "Wall", x = 1, y = 2, z = 3, orient = 1 })
			expect(a).never.to.equal(b)
		end)
		it("stairs keys IGNORE orient (any rotation claims the whole cell)", function()
			local a = BuildMath.slotKey({ kind = "Stairs", x = 1, y = 2, z = 3, orient = 0 })
			local b = BuildMath.slotKey({ kind = "Stairs", x = 1, y = 2, z = 3, orient = 3 })
			expect(a).to.equal(b)
		end)
		it("kinds never collide on the same cell", function()
			local floor = BuildMath.slotKey({ kind = "Floor", x = 1, y = 2, z = 3, orient = 0 })
			local stairs = BuildMath.slotKey({ kind = "Stairs", x = 1, y = 2, z = 3, orient = 0 })
			expect(floor).never.to.equal(stairs)
		end)
	end)

	describe("validateSlot", function()
		it("accepts every legal kind/orient combination, including negative cells", function()
			expect(BuildMath.validateSlot(config, "Wall", -5, 0, 5, 1)).to.be.ok()
			expect(BuildMath.validateSlot(config, "Floor", 0, -100, 0, 0)).to.be.ok()
			expect(BuildMath.validateSlot(config, "Stairs", 1, 2, 3, 3)).to.be.ok()
		end)
		it("returns a fresh slot with the given scalars", function()
			local slot = BuildMath.validateSlot(config, "Wall", 1, 2, 3, 0)
			expect(slot.kind).to.equal("Wall")
			expect(slot.x).to.equal(1)
			expect(slot.y).to.equal(2)
			expect(slot.z).to.equal(3)
			expect(slot.orient).to.equal(0)
		end)
		it("rejects unknown kinds and non-string kinds", function()
			expect(BuildMath.validateSlot(config, "Roof", 0, 0, 0, 0)).to.equal(nil)
			expect(BuildMath.validateSlot(config, 5, 0, 0, 0, 0)).to.equal(nil)
			expect(BuildMath.validateSlot(config, nil, 0, 0, 0, 0)).to.equal(nil)
		end)
		it("rejects non-finite, fractional, and out-of-bounds cell indices", function()
			expect(BuildMath.validateSlot(config, "Wall", 0 / 0, 0, 0, 0)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Wall", math.huge, 0, 0, 0)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Wall", 1.5, 0, 0, 0)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Wall", 101, 0, 0, 0)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Wall", 0, -101, 0, 0)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Wall", "1", 0, 0, 0)).to.equal(nil)
		end)
		it("rejects orients outside the kind's range", function()
			expect(BuildMath.validateSlot(config, "Wall", 0, 0, 0, 2)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Wall", 0, 0, 0, -1)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Floor", 0, 0, 0, 1)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Stairs", 0, 0, 0, 4)).to.equal(nil)
			expect(BuildMath.validateSlot(config, "Stairs", 0, 0, 0, 0.5)).to.equal(nil)
		end)
	end)
end
