--[[
	One-time init for the XP client views: the XP bar and the award banner feed.
	Both handle their own lifecycles (the bar re-attaches per life since VitalsGui is
	ResetOnSpawn = true; the feed is a persistent remote listener), so no per-character
	setup is needed here.
]]

local XPSystem_ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.XPSystem_ScriptStorage

require(XPSystem_ScriptStorage.XPGuiManager).init()
require(XPSystem_ScriptStorage.XPBannerFeed).init()
