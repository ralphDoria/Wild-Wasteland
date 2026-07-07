--[[
	Hunger/Thirst VIEW (Tier 3 rewrite). The simulation lives on the server
	(VitalsSystem_Server/VitalsService) and replicates via player attributes
	("Hunger"/"Thirst"); this module only renders:
	- the circular GUI bar (StatGuiManager)
	- the threshold-crossing rumble/gulp sound, on DOWNWARD crossings only
	  (restores from future food/drink shouldn't rumble)
	- the low-value tint toward the stat color

	The old client decay loops, the module-level shared threshold event (BUGS.md M11),
	and the hungerThirstDamage remote (C9) are all gone.
]]

local RS = game:GetService("ReplicatedStorage")
local VitalsSystem_ScriptStorage = RS.RojoManaged_RS.VitalsSystem_ScriptStorage
local References = require(VitalsSystem_ScriptStorage.Data.References)
local VitalsConfig = require(VitalsSystem_ScriptStorage.Data.VitalsConfig)
local VitalsSim = require(VitalsSystem_ScriptStorage.Sim.VitalsSim)

local soundsTbl: { [string]: Sound? } = {
	Thirst = References.SoundService:FindFirstChild("Gulping Water Glottal Croaks Slurp Water 1 (SFX)", true),
	Hunger = References.SoundService:FindFirstChild("StomachRumble", true),
}

local statColors: { [string]: Color3 } = {
	Thirst = Color3.fromRGB(198, 204, 19),
	Hunger = Color3.fromRGB(255, 123, 0),
}

export type hungerThirstObject = {
	statGuiObject: any,
	currentThresholdSection: number,
	trove: any,
}

local HungerThirstManager = {}

function HungerThirstManager.new(option: "Hunger" | "Thirst"): hungerThirstObject
	local config = VitalsConfig[option]
	local thresholds = config.thresholds
	local statGuiObject = References.StatGuiManager.new(
		References.VitalsGui:WaitForChild("Frame"):WaitForChild(option),
		option,
		statColors[option]
	)
	local trove = References.Trove.new()
	local sound = soundsTbl[option]
	local player = References.player

	local self: hungerThirstObject = {
		statGuiObject = statGuiObject,
		currentThresholdSection = #thresholds - 1,
		trove = trove,
	}

	local function render(value: number)
		local proportion = math.clamp(value / config.max, 0, 1)
		References.StatGuiManager.SetStatValue(statGuiObject, proportion)

		local newSection = VitalsSim.findThresholdSection(thresholds, proportion)
		if newSection < self.currentThresholdSection and sound then
			sound:Play()
		end
		self.currentThresholdSection = newSection

		-- Tint from white toward the stat color as the bar falls below the
		-- second-highest threshold (same mapping as pre-rewrite, plus an explicit
		-- restore to white so refills clean up after themselves).
		local canvasGroup = References.StatGuiManager.getCanvasGroup(statGuiObject)
		local tintStart = thresholds[#thresholds - 1]
		if proportion < tintStart then
			local alpha = math.clamp(proportion / tintStart, 0, 1)
			canvasGroup.GroupColor3 = statGuiObject.color:Lerp(Color3.new(1, 1, 1), alpha)
		else
			canvasGroup.GroupColor3 = Color3.new(1, 1, 1)
		end
	end

	local initial = player:GetAttribute(option)
	render(if typeof(initial) == "number" then initial else config.max)

	trove:Connect(player:GetAttributeChangedSignal(option), function()
		local value = player:GetAttribute(option)
		if typeof(value) == "number" then
			render(value)
		end
	end)

	return self
end

function HungerThirstManager.Destroy(self: hungerThirstObject)
	self.trove:Destroy()
	References.StatGuiManager.Destroy(self.statGuiObject)
	table.clear(self)
end

return HungerThirstManager
