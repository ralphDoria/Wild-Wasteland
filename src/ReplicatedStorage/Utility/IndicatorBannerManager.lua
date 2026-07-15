--!strict
--[[
	General-purpose event indicator banners (StarterGui.IndicatorBannerGui): the
	"what you did — what you gained" feed to the right of the crosshair. Client-only,
	purely cosmetic — real state (XP, kills, pickups) is replicated by its own system;
	this just announces it.

	API (call from any client code):
		IndicatorBannerManager.show("Killed Dummy", "+50 XP")
		IndicatorBannerManager.show("Discovered the Vault") -- gain text is optional

	Stacking is code-driven (the GUI has no UIListLayout, by design): each banner is a
	clone of BannerList.Template. A new banner slides in from outside BannerList's left
	edge (BannerList is a plain Frame with ClipsDescendants — scissor clipping works at
	every graphics quality level, unlike a CanvasGroup composite, which silently stops
	clipping when the engine falls back to direct rendering) into slot 0 at crosshair
	height, and every live banner tweens one slot down. After HOLD_SECONDS fully visible
	it slides back out left and is destroyed. Banners pushed to slot 3+ fade by slot
	("fade after 3 stacked"), and past the last slot they're dropped outright.
]]

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local playSound = require(script.Parent.PlaySoundUtil)

local ROW_HEIGHT = 28 -- Template height (24) + gap (4)
local HOLD_SECONDS = 2 -- time fully in view before sliding back out
local SLIDE_IN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local SLIDE_OUT_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.In)
local SHIFT_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FADE_INFO = SHIFT_INFO -- slot fade rides along with the shift

-- Extra transparency per slot (0 = top). Slots 0-2 solid, then fading; past the last
-- entry a banner is destroyed. GainText's stroke starts at 0.3, so its fade is remapped.
local SLOT_TRANSPARENCY = { 0, 0, 0, 0.45, 0.7, 0.85 }
local MAX_BANNERS = #SLOT_TRANSPARENCY
local GAIN_STROKE_BASE = 0.3

type Banner = {
	frame: Frame,
	actionText: TextLabel,
	gainText: TextLabel,
	slot: number,
}

local IndicatorBannerManager = {}

local bannerList: Frame? = nil
local template: Frame? = nil
local active: { Banner } = {} -- index 1 = newest (slot 0)

-- Played locally (PlaySoundUtil with no parent -> PlayLocalSound) on every show().
local bannerSound: Sound? = nil
local warnedMissingSound = false

local function getBannerSound(): Sound?
	if bannerSound and bannerSound.Parent then
		return bannerSound
	end
	local found: Instance? = SoundService:FindFirstChild("SoundStorage")
	found = found and found:FindFirstChild("Game")
	found = found and found:FindFirstChild("Experience")
	found = found and found:FindFirstChild("ExperienceGained")
	if found and found:IsA("Sound") then
		bannerSound = found
	elseif not warnedMissingSound then
		warnedMissingSound = true
		warn("[IndicatorBannerManager] SoundStorage.Game.Experience.ExperienceGained missing — banners will be silent")
	end
	return bannerSound
end

local function getGui(): (Frame?, Frame?)
	if bannerList and bannerList.Parent then
		return bannerList, template
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("IndicatorBannerGui", 10)
	if not gui then
		warn("[IndicatorBannerManager] IndicatorBannerGui missing — banners disabled (was the place saved?)")
		return nil, nil
	end
	bannerList = gui:WaitForChild("BannerList") :: Frame
	template = bannerList:WaitForChild("Template") :: Frame
	return bannerList, template
end

local function slotPosition(slot: number): UDim2
	return UDim2.new(0, 0, 0, slot * ROW_HEIGHT)
end

-- Fully left of the clipping BannerList frame, with slack for banners wider than it.
local function offscreenX(list: Frame): number
	return -(list.AbsoluteSize.X + 100)
end

local function applySlotFade(banner: Banner, tweenInfo: TweenInfo)
	local fade = SLOT_TRANSPARENCY[banner.slot + 1] or 1
	TweenService:Create(banner.frame, tweenInfo, { BackgroundTransparency = fade }):Play()
	TweenService:Create(banner.actionText, tweenInfo, { TextTransparency = fade }):Play()
	TweenService:Create(banner.gainText, tweenInfo, {
		TextTransparency = fade,
		TextStrokeTransparency = GAIN_STROKE_BASE + (1 - GAIN_STROKE_BASE) * fade,
	}):Play()
end

local function dismiss(banner: Banner)
	local index = table.find(active, banner)
	if not index then
		return -- already dropped (pushed past the last slot)
	end
	table.remove(active, index)
	local list = bannerList
	if not list then
		banner.frame:Destroy()
		return
	end
	local out = TweenService:Create(banner.frame, SLIDE_OUT_INFO, {
		Position = UDim2.new(0, offscreenX(list), 0, banner.slot * ROW_HEIGHT),
	})
	out.Completed:Once(function()
		banner.frame:Destroy()
	end)
	out:Play()
end

--[[
	Show a banner: `actionText` is what the player did ("Killed Dummy"), `gainText`
	(optional) is what they got ("+50 XP").
]]
function IndicatorBannerManager.show(actionText: string, gainText: string?)
	local list, tmpl = getGui()
	if not list or not tmpl then
		return
	end

	-- Everyone already on screen slides one slot down (and fades per its new slot);
	-- anything pushed past the last slot is dropped outright.
	for i = #active, 1, -1 do
		local banner = active[i]
		banner.slot += 1
		if banner.slot >= MAX_BANNERS then
			table.remove(active, i)
			banner.frame:Destroy()
		else
			TweenService:Create(banner.frame, SHIFT_INFO, { Position = slotPosition(banner.slot) }):Play()
			applySlotFade(banner, FADE_INFO)
		end
	end

	local frame = tmpl:Clone()
	frame.Name = "Banner"
	local banner: Banner = {
		frame = frame,
		actionText = frame:FindFirstChild("ActionText") :: TextLabel,
		gainText = frame:FindFirstChild("GainText") :: TextLabel,
		slot = 0,
	}
	banner.actionText.Text = actionText
	banner.gainText.Text = gainText or ""
	frame.Position = UDim2.new(0, offscreenX(list), 0, 0)
	frame.Visible = true
	frame.Parent = list
	table.insert(active, 1, banner)

	TweenService:Create(frame, SLIDE_IN_INFO, { Position = slotPosition(0) }):Play()
	task.delay(SLIDE_IN_INFO.Time + HOLD_SECONDS, dismiss, banner)

	local sound = getBannerSound()
	if sound then
		playSound(sound)
	end
end

return IndicatorBannerManager
