--!nocheck
--[[
	Pins the pure vitals math (VitalsSystem_ScriptStorage/Sim/VitalsSim) that the server
	sim and the client stamina prediction share. Guards the Tier 3 rewrite's core:
	decay/starvation arithmetic (BUGS.md C9/M12 replacement), threshold sectioning
	(M11 replacement), and stamina clamp semantics (M10).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VitalsSim = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.Sim.VitalsSim)

local staminaConfig = {
	max = 100,
	drainPerSecond = 5,
	regenPerSecond = 10,
	regenCooldown = 0.5,
}

return function()
	describe("decay", function()
		it("applies rate * dt", function()
			expect(VitalsSim.decay(100, 0.25, 4)).to.equal(99)
		end)

		it("clamps at zero instead of going negative", function()
			expect(VitalsSim.decay(0.1, 1, 1)).to.equal(0)
			expect(VitalsSim.decay(0, 1, 1)).to.equal(0)
		end)

		it("never increases the value", function()
			expect(VitalsSim.decay(50, 0, 10)).to.equal(50)
		end)
	end)

	describe("findThresholdSection", function()
		local thresholds = { 0, 0.1, 0.25, 0.5, 1 }

		it("maps interior proportions to their section", function()
			expect(VitalsSim.findThresholdSection(thresholds, 0.05)).to.equal(1)
			expect(VitalsSim.findThresholdSection(thresholds, 0.2)).to.equal(2)
			expect(VitalsSim.findThresholdSection(thresholds, 0.3)).to.equal(3)
			expect(VitalsSim.findThresholdSection(thresholds, 0.75)).to.equal(4)
		end)

		it("assigns exact boundaries to the lower section", function()
			expect(VitalsSim.findThresholdSection(thresholds, 0.1)).to.equal(1)
			expect(VitalsSim.findThresholdSection(thresholds, 0.25)).to.equal(2)
			expect(VitalsSim.findThresholdSection(thresholds, 0.5)).to.equal(3)
		end)

		it("handles the endpoints", function()
			expect(VitalsSim.findThresholdSection(thresholds, 0)).to.equal(1)
			expect(VitalsSim.findThresholdSection(thresholds, 1)).to.equal(4)
		end)

		it("clamps out-of-range proportions instead of failing", function()
			expect(VitalsSim.findThresholdSection(thresholds, -0.5)).to.equal(1)
			expect(VitalsSim.findThresholdSection(thresholds, 1.5)).to.equal(4)
		end)
	end)

	describe("staminaStep", function()
		it("drains and re-arms the regen cooldown while draining", function()
			local result = VitalsSim.staminaStep(100, 0, staminaConfig, 0.1, true)
			expect(result.stamina).to.be.near(99.5)
			expect(result.cooldownRemaining).to.equal(staminaConfig.regenCooldown)
		end)

		it("drain clamps at zero", function()
			local result = VitalsSim.staminaStep(0.2, 0, staminaConfig, 1, true)
			expect(result.stamina).to.equal(0)
		end)

		it("burns the cooldown down before regenerating", function()
			local result = VitalsSim.staminaStep(50, 0.5, staminaConfig, 0.2, false)
			expect(result.stamina).to.equal(50)
			expect(result.cooldownRemaining).to.be.near(0.3)
		end)

		it("cooldown clamps at zero", function()
			local result = VitalsSim.staminaStep(50, 0.1, staminaConfig, 1, false)
			expect(result.cooldownRemaining).to.equal(0)
		end)

		it("regenerates once the cooldown has expired", function()
			local result = VitalsSim.staminaStep(50, 0, staminaConfig, 0.5, false)
			expect(result.stamina).to.be.near(55)
			expect(result.cooldownRemaining).to.equal(0)
		end)

		it("regen clamps at max", function()
			local result = VitalsSim.staminaStep(99.9, 0, staminaConfig, 1, false)
			expect(result.stamina).to.equal(staminaConfig.max)
		end)

		it("regenerates when 'draining' at zero stamina (matches the old drainActive kick-out)", function()
			-- old behavior: drainActive flipped off at 0, so an exhausted sprinter regens
			local result = VitalsSim.staminaStep(0, 0, staminaConfig, 1, true)
			expect(result.stamina).to.be.near(10)
		end)
	end)

	describe("applyStaminaCost", function()
		it("subtracts the cost", function()
			expect(VitalsSim.applyStaminaCost(50, 10)).to.equal(40)
		end)

		it("clamps at zero when the cost exceeds the pool (BUGS.md M10)", function()
			expect(VitalsSim.applyStaminaCost(5, 10)).to.equal(0)
		end)
	end)

	describe("effectiveMovementMode (Batch V2, C2 replacement)", function()
		it("passes non-sprint modes through regardless of stamina", function()
			expect(VitalsSim.effectiveMovementMode("Default", 0)).to.equal("Default")
			expect(VitalsSim.effectiveMovementMode("Crouch", 0)).to.equal("Crouch")
		end)

		it("grants Sprint while stamina remains", function()
			expect(VitalsSim.effectiveMovementMode("Sprint", 0.1)).to.equal("Sprint")
			expect(VitalsSim.effectiveMovementMode("Sprint", 100)).to.equal("Sprint")
		end)

		it("downgrades Sprint to Default on an empty pool", function()
			expect(VitalsSim.effectiveMovementMode("Sprint", 0)).to.equal("Default")
			expect(VitalsSim.effectiveMovementMode("Sprint", -5)).to.equal("Default")
		end)
	end)

	describe("reconcile (Batch V2 client prediction)", function()
		it("keeps the prediction inside the tolerance", function()
			expect(VitalsSim.reconcile(50, 55, 15)).to.equal(50)
			expect(VitalsSim.reconcile(50, 35, 15)).to.equal(50)
		end)

		it("snaps to authority past the tolerance, in both directions", function()
			expect(VitalsSim.reconcile(50, 80, 15)).to.equal(80)
			expect(VitalsSim.reconcile(50, 20, 15)).to.equal(20)
		end)

		it("treats an exact-tolerance divergence as acceptable", function()
			expect(VitalsSim.reconcile(50, 65, 15)).to.equal(50)
		end)
	end)
end
