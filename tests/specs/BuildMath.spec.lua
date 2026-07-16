--!nocheck
--[[
	Pins the pure build-grid math (BuildSystem_ScriptStorage/Sim/BuildMath): snapping,
	the boundary-plane wall dedup guarantee, stairs geometry spanning the cell, occupancy
	keys, and the validateSlot trust boundary.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildMath = require(ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage.Sim.BuildMath)

-- Small deterministic test config (cell = 8) so specs don't drift with live tuning.
local config = {
	cellSize = 8,
	panelSize = Vector3.new(8, 8, 0.1),
	maxCellIndex = 100,
	structures = { Wall = { maxHealth = 1 }, Floor = { maxHealth = 1 }, Stairs = { maxHealth = 1 } },
}

local LOOK_NEG_Z = 0 -- yaw 0 looks toward -Z
local LOOK_NEG_X = math.pi / 2
local LOOK_POS_Z = math.pi
local LOOK_POS_X = -math.pi / 2

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

	describe("slotToCFrame + slotSize geometry", function()
		it("wall orient 0 sits ON the X boundary plane with its thin axis along X", function()
			local slot = { kind = "Wall", x = 1, y = 0, z = 0, orient = 0 }
			local cf = BuildMath.slotToCFrame(config, slot)
			expect(near(cf.Position.X, 8)).to.equal(true)
			expect(near(cf.Position.Y, 4)).to.equal(true)
			expect(near(cf.Position.Z, 4)).to.equal(true)
			-- Thin axis (local Z) must point along world X for a plane perpendicular to X.
			expect(near(math.abs(cf.ZVector.X), 1)).to.equal(true)
		end)
		it("floor lies flat with its thin axis vertical", function()
			local slot = { kind = "Floor", x = 0, y = 1, z = 0, orient = 0 }
			local cf = BuildMath.slotToCFrame(config, slot)
			expect(near(cf.Position.Y, 8)).to.equal(true)
			expect(near(math.abs(cf.ZVector.Y), 1)).to.equal(true)
		end)
		it("stairs bottom and top edges land exactly on the cell's edges", function()
			local slot = { kind = "Stairs", x = 0, y = 0, z = 0, orient = 0 } -- ascends +Z
			local cf = BuildMath.slotToCFrame(config, slot)
			local size = BuildMath.slotSize(config, slot)
			-- The panel's long axis is local Y; its ends are center +/- YVector * size.Y/2.
			local top = cf.Position + cf.YVector * (size.Y / 2)
			local bottom = cf.Position - cf.YVector * (size.Y / 2)
			expect(near(bottom.Y, 0)).to.equal(true) -- cell bottom
			expect(near(bottom.Z, 0)).to.equal(true) -- near edge
			expect(near(top.Y, 8)).to.equal(true) -- cell top
			expect(near(top.Z, 8)).to.equal(true) -- far edge (ascends +Z)
		end)
		it("stairs are stretched to the cell diagonal; walls and floors keep the panel size", function()
			local stairs = BuildMath.slotSize(config, { kind = "Stairs", x = 0, y = 0, z = 0, orient = 0 })
			expect(near(stairs.Y, 8 * math.sqrt(2))).to.equal(true)
			expect(near(stairs.X, 8)).to.equal(true)
			local wall = BuildMath.slotSize(config, { kind = "Wall", x = 0, y = 0, z = 0, orient = 0 })
			expect(wall).to.equal(config.panelSize)
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
