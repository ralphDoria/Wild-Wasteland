--!nocheck
--[[
	Pins the store→retrieve round-trip for base storage / profile persistence
	(HomeBaseSystem_ScriptStorage/ItemSerializer). A malformed persisted entry must be rejected,
	not crash deserialize; a serialized item must rehydrate to an equivalent tool.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSerializer = require(
	ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.ItemSerializer
)

local whitelist = {
	default = { "Quantity" },
	Stackable = { "Quantity" },
	Gun = { "Quantity", "Ammo", "AmmoReserve" },
}

-- Build a fake Tool with the given Type/attributes (real Instance — spec runs in-engine).
local function makeTool(name, toolType, attrs)
	local tool = Instance.new("Tool")
	tool.Name = name
	if toolType then tool:SetAttribute("Type", toolType) end
	for k, v in attrs or {} do
		tool:SetAttribute(k, v)
	end
	return tool
end

return function()
	describe("serialize", function()
		it("captures the tool name and whitelisted attributes only", function()
			local tool = makeTool("Raider Axe", "Melee", { Quantity = 1, Junk = "ignore-me" })
			local entry = ItemSerializer.serialize(tool, whitelist)
			expect(entry.tag).to.equal("Raider Axe")
			expect(entry.quantity).to.equal(1)
			expect(entry.attributes.Junk).to.never.be.ok() -- not whitelisted
		end)

		it("defaults quantity to 1 when the attribute is absent", function()
			local tool = makeTool("Night Vision Goggles", "Wearable", {})
			local entry = ItemSerializer.serialize(tool, whitelist)
			expect(entry.quantity).to.equal(1)
		end)

		it("persists per-type whitelisted attributes (gun ammo)", function()
			local tool = makeTool("Beretta", "Gun", { Quantity = 1, Ammo = 12, AmmoReserve = 45, Heat = 3 })
			local entry = ItemSerializer.serialize(tool, whitelist)
			expect(entry.attributes.Ammo).to.equal(12)
			expect(entry.attributes.AmmoReserve).to.equal(45)
			expect(entry.attributes.Heat).to.never.be.ok() -- Gun whitelist excludes Heat
		end)
	end)

	describe("isValidEntry", function()
		it("accepts a well-formed entry", function()
			expect(ItemSerializer.isValidEntry({ tag = "Caps", quantity = 5, attributes = {} })).to.equal(true)
		end)
		it("rejects missing/empty tag, bad quantity, and non-table attributes", function()
			expect(ItemSerializer.isValidEntry({ tag = "", quantity = 1, attributes = {} })).to.equal(false)
			expect(ItemSerializer.isValidEntry({ tag = "X", quantity = -1, attributes = {} })).to.equal(false)
			expect(ItemSerializer.isValidEntry({ tag = "X", quantity = 0 / 0, attributes = {} })).to.equal(false)
			expect(ItemSerializer.isValidEntry({ tag = "X", quantity = 1, attributes = "nope" })).to.equal(false)
			expect(ItemSerializer.isValidEntry("not a table")).to.equal(false)
		end)
	end)

	describe("deserialize", function()
		it("round-trips a serialized item back onto a spawned tool", function()
			local original = makeTool("Light Bullets", "Stackable", { Quantity = 30 })
			local entry = ItemSerializer.serialize(original, whitelist)

			-- Inject a fake spawn that mimics ServerSpawnTool (clone-from-catalog).
			local spawned
			local function fakeSpawn(toolName, parent)
				spawned = makeTool(toolName, "Stackable", {})
				spawned.Parent = parent
				return spawned
			end

			local holder = Instance.new("Folder")
			local tool = ItemSerializer.deserialize(entry, fakeSpawn, holder)
			expect(tool).to.be.ok()
			expect(tool.Name).to.equal("Light Bullets")
			expect(tool:GetAttribute("Quantity")).to.equal(30)
		end)

		it("returns nil (no crash) on a malformed entry", function()
			local function fakeSpawn() error("should not be called") end
			expect(ItemSerializer.deserialize({ tag = 123 }, fakeSpawn, Instance.new("Folder"))).to.never.be.ok()
		end)

		it("returns nil when the catalog has no such tool", function()
			local function fakeSpawn() return nil end
			local entry = { tag = "Nonexistent", quantity = 1, attributes = {} }
			expect(ItemSerializer.deserialize(entry, fakeSpawn, Instance.new("Folder"))).to.never.be.ok()
		end)
	end)
end
