--[[
	One-time init for the XP client views: the XP bar, the award banner feed, and the
	level-up presentation (terminal typewriter + sting). The managers handle their own
	lifecycles (the bar re-attaches per life since VitalsGui is ResetOnSpawn = true;
	the feed and typewriter are persistent), so no per-character setup is needed here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local XPSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.XPSystem_ScriptStorage
local Utility = ReplicatedStorage.RojoManaged_RS.Utility

local XPGuiManager = require(XPSystem_ScriptStorage.XPGuiManager)
local TerminalTypewriterManager = require(Utility.TerminalTypewriterManager)
local playSound = require(Utility.PlaySoundUtil)

XPGuiManager.init()
require(XPSystem_ScriptStorage.XPBannerFeed).init()

-- Level-up moment: type "LEVEL N" at the crosshair and play the sting locally.
-- (levelUp fires per derived-level increase; multi-level jumps fire once per XP change
-- with the final level, so one presentation per gain.)
local levelUpSting = SoundService:WaitForChild("SoundStorage"):WaitForChild("Game")
	:WaitForChild("Experience"):FindFirstChild("Jungle Jazz Room Sting")
if not levelUpSting then
	warn("[XPGuiExecutor] Jungle Jazz Room Sting missing — level-up will be silent")
end

XPGuiManager.levelUp:Connect(function(newLevel: number)
	TerminalTypewriterManager.play(`LEVEL {newLevel}`)
	if levelUpSting then
		playSound(levelUpSting)
	end
end)
