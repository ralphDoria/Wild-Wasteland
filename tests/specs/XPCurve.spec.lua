--!nocheck
--[[
	Pins the pure level-curve math (XPSystem_ScriptStorage/Sim/XPCurve): level is DERIVED
	from cumulative XP, monotonic, clamped to [1, maxLevel]; progress() feeds the UI.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local XPCurve = require(ReplicatedStorage.RojoManaged_RS.XPSystem_ScriptStorage.Sim.XPCurve)

-- Small deterministic test curve: 1->2 costs 100, 2->3 costs 200, 3->4 costs 400; cap 4.
local curve = { baseXP = 100, growthRate = 2, maxLevel = 4 }

return function()
	describe("xpToAdvance", function()
		it("grows the per-level requirement by growthRate", function()
			expect(XPCurve.xpToAdvance(curve, 1)).to.equal(100)
			expect(XPCurve.xpToAdvance(curve, 2)).to.equal(200)
			expect(XPCurve.xpToAdvance(curve, 3)).to.equal(400)
		end)
		it("never advances at or above the cap", function()
			expect(XPCurve.xpToAdvance(curve, 4)).to.equal(math.huge)
			expect(XPCurve.xpToAdvance(curve, 99)).to.equal(math.huge)
		end)
	end)

	describe("totalXPForLevel", function()
		it("is cumulative from level 1 = 0", function()
			expect(XPCurve.totalXPForLevel(curve, 1)).to.equal(0)
			expect(XPCurve.totalXPForLevel(curve, 2)).to.equal(100)
			expect(XPCurve.totalXPForLevel(curve, 3)).to.equal(300)
			expect(XPCurve.totalXPForLevel(curve, 4)).to.equal(700)
		end)
		it("clamps levels beyond the cap to the cap's total", function()
			expect(XPCurve.totalXPForLevel(curve, 10)).to.equal(700)
		end)
	end)

	describe("levelForTotalXP", function()
		it("round-trips every level threshold", function()
			for level = 1, curve.maxLevel do
				local total = XPCurve.totalXPForLevel(curve, level)
				expect(XPCurve.levelForTotalXP(curve, total)).to.equal(level)
				-- One XP short of the threshold is still the previous level.
				if level > 1 then
					expect(XPCurve.levelForTotalXP(curve, total - 1)).to.equal(level - 1)
				end
			end
		end)
		it("clamps to level 1 for zero/negative XP and to maxLevel for huge XP", function()
			expect(XPCurve.levelForTotalXP(curve, 0)).to.equal(1)
			expect(XPCurve.levelForTotalXP(curve, -50)).to.equal(1)
			expect(XPCurve.levelForTotalXP(curve, 1e9)).to.equal(curve.maxLevel)
		end)
	end)

	describe("progress", function()
		it("reports position within the current level", function()
			-- 150 XP = level 2 (needs 100) with 50 into the 200-cost level.
			local p = XPCurve.progress(curve, 150)
			expect(p.level).to.equal(2)
			expect(p.intoLevel).to.equal(50)
			expect(p.required).to.equal(200)
			expect(p.fraction).to.equal(0.25)
		end)
		it("is a full bar at the cap", function()
			local p = XPCurve.progress(curve, 700)
			expect(p.level).to.equal(4)
			expect(p.fraction).to.equal(1)
		end)
		it("keeps counting XP past the cap (retro-levels on a cap raise)", function()
			local p = XPCurve.progress(curve, 5000)
			expect(p.level).to.equal(4)
			expect(p.intoLevel).to.equal(5000 - 700)
		end)
	end)
end
