--!strict
--[[
	Client feed: turns XPService's outbound `XPAwarded` notification into an indicator
	banner ("Killed Dummy — +50 XP") via the general-purpose IndicatorBannerManager.
	Purely cosmetic — the authoritative XP change replicates separately as the XP
	attribute (which drives the XP bar).

	New award names show their raw key as the action text until given a formatter in
	ACTION_FORMATS, so a new award is visible (if unpolished) with zero changes here.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local IndicatorBannerManager = require(ReplicatedStorage.RojoManaged_RS.Utility.IndicatorBannerManager)

-- awardName -> action-text formatter. `detail` is the server-provided flavor
-- (victim name for kills); always assume it can be nil.
local ACTION_FORMATS: { [string]: (detail: string?) -> string } = {
	KillNPC = function(detail)
		return `Killed {detail or "an enemy"}`
	end,
	KillPlayer = function(detail)
		return `Killed {detail or "a player"}`
	end,
}

local XPBannerFeed = {}

function XPBannerFeed.init()
	-- XPSystem_Storage + XPAwarded are created by XPService.init at server start.
	local storage = ReplicatedStorage:WaitForChild("XPSystem_Storage", 10)
	if not storage then
		warn("[XPBannerFeed] XPSystem_Storage missing — XP banners disabled (XPService not running?)")
		return
	end
	local xpAwarded = storage:WaitForChild("XPAwarded") :: RemoteEvent

	xpAwarded.OnClientEvent:Connect(function(awardName: string, amount: number, detail: string?)
		local format = ACTION_FORMATS[awardName]
		local actionText = if format then format(detail) else awardName
		IndicatorBannerManager.show(actionText, `+{amount} XP`)
	end)
end

return XPBannerFeed
