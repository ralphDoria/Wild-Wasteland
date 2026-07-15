--!strict
--[[
	Server-authoritative level/XP progression (docs/XP_SYSTEM_RESEARCH.md).

	The SINGLE award surface: all XP enters through `award(player, awardName)` — a client
	claim can never grant XP. The only remote is `XPAwarded` (created in init, in the
	runtime `XPSystem_Storage` folder): an OUTBOUND notification fired to the awardee so
	the client can show an indicator banner ("Killed Dummy — +50 XP"). It has no
	OnServerEvent listener, so it is not a grant surface. Kill XP is attributed at the
	two validated damage sites (MeleeReceiver.Hit, GunReceiver) via `notifyDamageDealt`,
	called right after Humanoid:TakeDamage.

	State/replication follows the vitals pattern: the durable stat is the "XP" player
	attribute (persisted by DataSaveSystem via PlayerStatsInfo.getPersisted); "Level" is
	derived from it with the pure XPCurve and never stored. Client UI listens to
	GetAttributeChangedSignal. Other SERVER systems can react to level-ups via the
	`levelUp` signal (player, newLevel, oldLevel).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local XPSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.XPSystem_ScriptStorage
local XPConfig = require(XPSystem_ScriptStorage.Data.XPConfig)
local XPCurve = require(XPSystem_ScriptStorage.Sim.XPCurve)
local GoodSignal = require(ReplicatedStorage.Packages.GoodSignal)

local XP_ATTRIBUTE = "XP"
local LEVEL_ATTRIBUTE = "Level"

local XPService = {}

-- Fired as (player, newLevel, oldLevel) after the Level attribute updates.
XPService.levelUp = GoodSignal.new()

-- Victims already credited for their death, so exactly one kill award fires per death
-- even if several damage events land on the same frame. Weak keys: dead humanoids GC.
local creditedKills: { [Humanoid]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- Outbound-only banner notification (created in init; see header). Nil until then —
-- awards still grant without it, they just don't announce.
local xpAwardedRemote: RemoteEvent? = nil

-- Recompute the derived Level attribute from total XP; fire levelUp on an increase.
local function updateLevel(player: Player, totalXP: number)
	local oldLevel = player:GetAttribute(LEVEL_ATTRIBUTE)
	local newLevel = XPCurve.levelForTotalXP(XPConfig.curve, totalXP)
	if oldLevel ~= newLevel then
		player:SetAttribute(LEVEL_ATTRIBUTE, newLevel)
		if typeof(oldLevel) == "number" and newLevel > oldLevel then
			XPService.levelUp:Fire(player, newLevel, oldLevel)
		end
	end
end

--[[
	Grant the configured XP for `awardName` (a key of XPConfig.awards) to a player.
	The ONLY way XP enters the system. Unknown award names warn and grant nothing, so a
	typo'd call site is loud instead of silently generous. `detail` is optional flavor
	for the client banner (e.g. the victim's name for kills) — never gameplay-relevant.
]]
function XPService.award(player: Player, awardName: string, detail: string?)
	local amount = XPConfig.awards[awardName]
	if not amount then
		warn(`[XPService] Unknown award "{awardName}" — add it to XPConfig.awards`)
		return
	end
	-- Before DataSaveSystem finishes loading, the XP attribute is nil/stale and the load
	-- would overwrite anything we add. Drop the award loudly (research doc: known seam).
	if player:GetAttribute("StatsLoaded") ~= true then
		warn(`[XPService] Dropped award "{awardName}" for {player.Name}: stats not loaded yet`)
		return
	end
	local totalXP = (player:GetAttribute(XP_ATTRIBUTE) :: number? or 0) + amount
	player:SetAttribute(XP_ATTRIBUTE, totalXP)
	updateLevel(player, totalXP)
	if xpAwardedRemote then
		xpAwardedRemote:FireClient(player, awardName, amount, detail)
	end
end

--[[
	Kill attribution (killing-blow model). Call from a validated server damage path right
	AFTER Humanoid:TakeDamage; if that damage was lethal, the attacker is credited once.
	ForceField-blocked damage never trips this (Health stays > 0).
]]
function XPService.notifyDamageDealt(attacker: Player, victim: Humanoid)
	if victim.Health > 0 or creditedKills[victim] then
		return
	end
	creditedKills[victim] = true
	local victimPlayer = Players:GetPlayerFromCharacter(victim.Parent)
	local victimName = if victim.Parent then victim.Parent.Name else nil
	XPService.award(attacker, if victimPlayer then "KillPlayer" else "KillNPC", victimName)
end

function XPService.init()
	-- Runtime-created storage + notification remote (same pattern as MovementIntent:
	-- nothing exploit-relevant lives in the Studio place).
	local storage = ReplicatedStorage:FindFirstChild("XPSystem_Storage")
	if not storage then
		storage = Instance.new("Folder")
		storage.Name = "XPSystem_Storage"
		storage.Parent = ReplicatedStorage
	end
	local remote = Instance.new("RemoteEvent")
	remote.Name = "XPAwarded"
	remote.Parent = storage
	xpAwardedRemote = remote

	local function onPlayerAdded(player: Player)
		-- Derive Level as soon as the persisted XP is in (or immediately on a re-init).
		if player:GetAttribute("StatsLoaded") == true then
			updateLevel(player, player:GetAttribute(XP_ATTRIBUTE) :: number? or 0)
		else
			local connection: RBXScriptConnection
			connection = player:GetAttributeChangedSignal("StatsLoaded"):Connect(function()
				connection:Disconnect()
				updateLevel(player, player:GetAttribute(XP_ATTRIBUTE) :: number? or 0)
			end)
		end
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
end

return XPService
