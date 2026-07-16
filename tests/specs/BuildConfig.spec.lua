--!nocheck
--[[
	Shape test for the live build config (BuildSystem_ScriptStorage/Data/BuildConfig):
	the grid must derive from the panel, the three structure kinds must exist with sane
	stats, and every tunable must be a positive finite number. Catches a bad tweak before
	it silently breaks the grid or the construction ramp.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BuildConfig = require(ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage.Data.BuildConfig)

local function isPositiveFinite(n)
	return typeof(n) == "number" and n == n and n > 0 and n < math.huge
end

return function()
	describe("panel and grid derivation", function()
		it("panel face is square (the cell is cubic)", function()
			expect(BuildConfig.panelSize.X).to.equal(BuildConfig.panelSize.Y)
		end)
		it("cellSize derives from the panel face", function()
			expect(BuildConfig.cellSize).to.equal(BuildConfig.panelSize.X)
		end)
		it("panel is a thin panel, not a block", function()
			expect(BuildConfig.panelSize.Z < BuildConfig.panelSize.X).to.equal(true)
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
		it("timing and range knobs are positive finite numbers", function()
			for _, key in { "buildTime", "maxBuildRange", "rangeSlack", "placementCooldown", "rampTickInterval", "maxCellIndex", "cellSize" } do
				expect(isPositiveFinite(BuildConfig[key])).to.equal(true)
			end
		end)
		it("spawnHealthFraction is a real fraction", function()
			expect(BuildConfig.spawnHealthFraction > 0).to.equal(true)
			expect(BuildConfig.spawnHealthFraction < 1).to.equal(true)
		end)
		it("transparencies are renderable", function()
			expect(BuildConfig.previewTransparency > 0).to.equal(true)
			expect(BuildConfig.previewTransparency < 1).to.equal(true)
			expect(BuildConfig.constructionStartTransparency > 0).to.equal(true)
			expect(BuildConfig.constructionStartTransparency < 1).to.equal(true)
		end)
		it("template and folder names are non-empty strings", function()
			expect(#BuildConfig.assetsFolderName > 0).to.equal(true)
			expect(#BuildConfig.templateName > 0).to.equal(true)
			expect(#BuildConfig.storageFolderName > 0).to.equal(true)
		end)
	end)
end
