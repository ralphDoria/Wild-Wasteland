--[[
	One-time init for the XP bar view. The manager handles the per-life re-attach itself
	(the bar lives inside VitalsGui, which is ResetOnSpawn = true), so no per-character
	setup is needed here.
]]

local XPGuiManager =
	require(game:GetService("ReplicatedStorage").RojoManaged_RS.XPSystem_ScriptStorage.XPGuiManager)

XPGuiManager.init()
