--!nocheck
--[[
	Shape test for the live build config (BuildSystem_ScriptStorage/Data/BuildConfig):
	the grid must derive from the panel piece (whatever axis its thickness is on — the
	RustyMetalSheet union is Y-thin), the three structure kinds must exist with sane
	stats, and every tunable must be a positive finite number. Catches a bad tweak before
	it silently breaks the grid, the region clamp, or the construction ramp.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage.Data.BuildConfig)

local function isPositiveFinite(n)
	return typeof(n) == "number" and n == n and n > 0 and n < math.huge
end

local function sortedComponents(v: Vector3): (number, number, number)
	local components = { v.X, v.Y, v.Z }
	table.sort(components)
	return components[1], components[2], components[3]
end

return function()
	describe("panel and grid derivation", function()
		it("panel face is square (the two largest dimensions match, whichever axes they're on)", function()
			local _, mid, largest = sortedComponents(BuildConfig.panelSize)
			expect(mid).to.equal(largest)
		end)
		it("cellSize derives from the panel face", function()
			local _, _, largest = sortedComponents(BuildConfig.panelSize)
			expect(BuildConfig.cellSize).to.equal(largest)
		end)
		it("panel is a thin panel, not a block", function()
			local smallest, _, largest = sortedComponents(BuildConfig.panelSize)
			expect(smallest < largest).to.equal(true)
		end)
	end)

	describe("structures", function()
		it("declares exactly the three buildable kinds", function()
			expect(BuildConfig.structures.Wall).to.be.ok()
			expect(BuildConfig.structures.Floor).to.be.ok()
			expect(BuildConfig.structures.Stairs).to.be.ok()
			local count = 0
			for _ in BuildConfig.structures do
				count += 1
			end
			expect(count).to.equal(3)
		end)
		it("every structure has positive finite maxHealth", function()
			for kind, stats in BuildConfig.structures do
				expect(isPositiveFinite(stats.maxHealth)).to.equal(true)
			end
		end)
	end)

	describe("tunables", function()
		it("timing, range, and probe knobs are positive finite numbers", function()
			for _, key in { "buildTime", "maxBuildRange", "groundContactMargin", "floorSelectionAnchorYOffset", "placementCooldown", "rampTickInterval", "maxCellIndex", "cellSize" } do
				expect(isPositiveFinite(BuildConfig[key])).to.equal(true)
			end
		end)
		it("buildRegionRadiusCells is a whole number of cells, at least 1", function()
			expect(isPositiveFinite(BuildConfig.buildRegionRadiusCells)).to.equal(true)
			expect(BuildConfig.buildRegionRadiusCells % 1).to.equal(0)
			expect(BuildConfig.buildRegionRadiusCells >= 1).to.equal(true)
		end)
		it("spawnHealthFraction is a real fraction", function()
			expect(BuildConfig.spawnHealthFraction > 0).to.equal(true)
			expect(BuildConfig.spawnHealthFraction < 1).to.equal(true)
		end)
		it("preview colors are distinct Color3s and the construction transparency renderable", function()
			expect(typeof(BuildConfig.previewColor)).to.equal("Color3")
			expect(typeof(BuildConfig.previewInvalidColor)).to.equal("Color3")
			expect(BuildConfig.previewColor).never.to.equal(BuildConfig.previewInvalidColor)
			expect(BuildConfig.constructionStartTransparency > 0).to.equal(true)
			expect(BuildConfig.constructionStartTransparency < 1).to.equal(true)
		end)
		it("runtime instance names are non-empty strings", function()
			expect(#BuildConfig.storageFolderName > 0).to.equal(true)
			expect(#BuildConfig.templateName > 0).to.equal(true)
			expect(#BuildConfig.placedFolderName > 0).to.equal(true)
			expect(#BuildConfig.structureTag > 0).to.equal(true)
		end)
	end)
end
