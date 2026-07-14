--!strict
--[[
	Client view for the XP bar. Pure view: renders the replicated "XP" player attribute
	through the shared XPCurve math — it never mutates progression (XP has no remotes;
	XPService on the server is the only writer).

	The bar lives INSIDE VitalsGui (StarterGui.VitalsGui.Container.XPBar) so that
	VitalsManager's touch/desktop repositioning moves the icons and the bar as one unit.
	VitalsGui is ResetOnSpawn = true, so a fresh instance appears in PlayerGui every
	life — init() therefore re-attaches on each new VitalsGui instance instead of
	capturing references once.

	GUI contract (built in the place, 2026-07-14):
		VitalsGui.Container.XPBar.ProgressBar.Fill   -- width driven as UDim2.fromScale(fraction, 1)
		VitalsGui.Container.XPBar.ProgressBar.XPText -- "intoLevel / required XP" (MAX LEVEL at cap)
		VitalsGui.Container.XPBar.LevelLabel         -- "Level N"

	`XPGuiManager.levelUp` fires (newLevel, oldLevel) whenever the DERIVED level rises —
	the hook for the future level-up animation.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local XPSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.XPSystem_ScriptStorage
local XPConfig = require(XPSystem_ScriptStorage.Data.XPConfig)
local XPCurve = require(XPSystem_ScriptStorage.Sim.XPCurve)
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)

local XP_ATTRIBUTE = "XP"
local FILL_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local XPGuiManager = {}

-- Fired as (newLevel, oldLevel) after the bar re-renders a level increase.
XPGuiManager.levelUp = GoodSignal.new()

type BarRefs = {
	fill: Frame,
	xpText: TextLabel,
	levelLabel: TextLabel,
}

-- Refs into the CURRENT VitalsGui instance (replaced every respawn); nil until attached.
local currentRefs: BarRefs? = nil
local currentLevel: number? = nil

local function render(refs: BarRefs, totalXP: number, animate: boolean)
	local progress = XPCurve.progress(XPConfig.curve, totalXP)

	local fillSize = UDim2.fromScale(progress.fraction, 1)
	if animate then
		TweenService:Create(refs.fill, FILL_TWEEN_INFO, { Size = fillSize }):Play()
	else
		refs.fill.Size = fillSize
	end
	refs.levelLabel.Text = `Level {progress.level}`
	if progress.required == math.huge then
		refs.xpText.Text = "MAX LEVEL"
	else
		refs.xpText.Text = `{progress.intoLevel} / {progress.required} XP`
	end

	if currentLevel ~= nil and progress.level > currentLevel then
		XPGuiManager.levelUp:Fire(progress.level, currentLevel)
	end
	currentLevel = progress.level
end

local function getTotalXP(player: Player): number
	local totalXP = player:GetAttribute(XP_ATTRIBUTE)
	return if typeof(totalXP) == "number" then totalXP else 0
end

-- Resolve the bar inside a (fresh) VitalsGui instance and paint the current state.
local function attach(player: Player, vitalsGui: Instance)
	local container = vitalsGui:WaitForChild("Container")
	local xpBar = container:WaitForChild("XPBar")
	local progressBar = xpBar:WaitForChild("ProgressBar")
	local refs: BarRefs = {
		fill = progressBar:WaitForChild("Fill") :: Frame,
		xpText = progressBar:WaitForChild("XPText") :: TextLabel,
		levelLabel = xpBar:WaitForChild("LevelLabel") :: TextLabel,
	}
	currentRefs = refs
	render(refs, getTotalXP(player), false) -- snap, don't tween, on a fresh instance
end

function XPGuiManager.init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- One persistent attribute connection; it renders into whatever instance is current.
	player:GetAttributeChangedSignal(XP_ATTRIBUTE):Connect(function()
		local refs = currentRefs
		if refs and refs.fill.Parent ~= nil then
			render(refs, getTotalXP(player), true)
		end
	end)

	-- ResetOnSpawn: every life clones a fresh VitalsGui into PlayerGui — re-attach each time.
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == "VitalsGui" then
			task.spawn(attach, player, child)
		end
	end)
	local existing = playerGui:FindFirstChild("VitalsGui")
	if existing then
		task.spawn(attach, player, existing)
	end
end

return XPGuiManager
