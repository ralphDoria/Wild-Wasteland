--!strict
--[[
	Server-authoritative building (see docs/PLAYTEST_VERIFICATION.md → "Build system v1").

	The client can only ever REQUEST a slot: the one remote (`PlaceStructure`, created in
	init inside the runtime BuildSystem_Storage folder — nothing exploit-relevant lives in
	the Studio place) carries five flat scalars (kind, x, y, z, orient). All geometry is
	re-derived server-side through the same pure BuildMath the preview used, behind
	BuildMath.validateSlot — a client can never place at a raw position, only claim a
	legal grid slot near itself.

	Performance shape:
	- ONE Heartbeat accumulator (VitalsService pattern) steps every under-construction
	  structure at rampTickInterval; nothing ticks once construction finishes.
	- No per-structure scripts or connections: occupancy is released by a single
	  ChildRemoved listener on the PlacedStructures folder reading the SlotKey attribute.
	- Structure state is attributes (Health/MaxHealth/StructureType/SlotKey/OwnerUserId)
	  on an anchored clone of one shared template.

	Construction ramp (Fortnite-style): a placed structure exists and collides
	immediately at spawnHealthFraction of maxHealth, then gains health linearly over
	buildTime while its transparency eases to solid. Damage taken mid-ramp subtracts from
	the same Health attribute the ramp is adding to; hitting 0 at any point destroys it.

	Damage enters ONLY through `BuildService.damageStructure` — the hook for future
	weapon integration (one call per validated damage site, like XPService's
	notifyDamageDealt). No remote can modify health.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BuildSystem_ScriptStorage = ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage
local BuildConfig = require(BuildSystem_ScriptStorage.Data.BuildConfig)
local BuildMath = require(BuildSystem_ScriptStorage.Sim.BuildMath)
local getPanelTemplate = require(BuildSystem_ScriptStorage.Components.getPanelTemplate)

-- Shared server-authority boundary (Tier 2 layer) for the alive-sender check.
local Validation = require(
	game:GetService("ServerScriptService").RojoManaged_SSS.ItemSystem_Server.Revamp.Receivers.Validation
)

local STRUCTURE_TAG = "BuildStructure"
local PLACED_FOLDER_NAME = "PlacedStructures"

local HEALTH_ATTRIBUTE = "Health"
local MAX_HEALTH_ATTRIBUTE = "MaxHealth"
local STRUCTURE_TYPE_ATTRIBUTE = "StructureType"
local SLOT_KEY_ATTRIBUTE = "SlotKey"
local OWNER_ATTRIBUTE = "OwnerUserId"

type Construction = {
	part: BasePart,
	elapsed: number,
	maxHealth: number,
	healthPerSecond: number,
}

local BuildService = {}

local template: BasePart? = nil
local placedFolder: Folder? = nil

-- Slot key -> the structure occupying it. Released centrally by ChildRemoved.
local occupied: { [string]: BasePart } = {}
-- Structures still ramping up. Entries fall out on completion or destruction.
local underConstruction: { Construction } = {}
-- Per-player placement rate limit (os.clock; MeleeReceiver pattern).
local lastPlacement: { [Player]: number } = {}

local function stepConstruction(dt: number)
	for i = #underConstruction, 1, -1 do
		local entry = underConstruction[i]
		local part = entry.part
		if not part.Parent then
			-- Destroyed mid-build (damage or external cleanup).
			table.remove(underConstruction, i)
			continue
		end

		entry.elapsed += dt
		local alpha = math.min(entry.elapsed / BuildConfig.buildTime, 1)
		part.Transparency = BuildConfig.constructionStartTransparency * (1 - alpha)

		-- Ramp reads the live attribute so damage taken mid-build stays subtracted.
		local health = part:GetAttribute(HEALTH_ATTRIBUTE) :: number? or 0
		local newHealth = math.min(health + entry.healthPerSecond * dt, entry.maxHealth)
		if newHealth ~= health then
			part:SetAttribute(HEALTH_ATTRIBUTE, newHealth)
		end

		if alpha >= 1 then
			part.Transparency = 0
			table.remove(underConstruction, i)
		end
	end
end

local function spawnStructure(player: Player, slot: BuildMath.Slot, slotKey: string)
	local structureTemplate = template
	local folder = placedFolder
	if not structureTemplate or not folder then
		return
	end
	local stats = BuildConfig.structures[slot.kind]

	local part = structureTemplate:Clone()
	part.Name = slot.kind
	part.Size = BuildMath.slotSize(BuildConfig, slot)
	part.CFrame = BuildMath.slotToCFrame(BuildConfig, slot)
	part.Anchored = true
	part.CanCollide = true
	part.Transparency = BuildConfig.constructionStartTransparency

	part:SetAttribute(HEALTH_ATTRIBUTE, stats.maxHealth * BuildConfig.spawnHealthFraction)
	part:SetAttribute(MAX_HEALTH_ATTRIBUTE, stats.maxHealth)
	part:SetAttribute(STRUCTURE_TYPE_ATTRIBUTE, slot.kind)
	part:SetAttribute(SLOT_KEY_ATTRIBUTE, slotKey)
	part:SetAttribute(OWNER_ATTRIBUTE, player.UserId)
	CollectionService:AddTag(part, STRUCTURE_TAG)

	occupied[slotKey] = part
	part.Parent = folder
	table.insert(underConstruction, {
		part = part,
		elapsed = 0,
		maxHealth = stats.maxHealth,
		healthPerSecond = stats.maxHealth * (1 - BuildConfig.spawnHealthFraction) / BuildConfig.buildTime,
	})
end

local function onPlaceRequest(player: Player, kind: unknown, x: unknown, y: unknown, z: unknown, orient: unknown)
	-- Trust boundary: five scalars in, a validated Slot (or silence) out.
	local slot = BuildMath.validateSlot(BuildConfig, kind, x, y, z, orient)
	if not slot then
		return
	end

	local character = Validation.getAliveCharacter(player)
	if not character then
		return
	end

	local now = os.clock()
	local last = lastPlacement[player]
	if last and now - last < BuildConfig.placementCooldown then
		return
	end

	-- Range: character pivot to slot CENTER (the client measured camera->hit, hence the
	-- slack — see BuildConfig).
	local distance = (character:GetPivot().Position - BuildMath.slotCenter(BuildConfig, slot)).Magnitude
	if distance > BuildConfig.maxBuildRange + BuildConfig.rangeSlack then
		return
	end

	local slotKey = BuildMath.slotKey(slot)
	if occupied[slotKey] then
		return
	end

	lastPlacement[player] = now
	spawnStructure(player, slot, slotKey)
end

--[[
	The ONLY way structure health changes. Accepts the structure part or any descendant
	of it (future weapon hits will hand over whatever instance the ray/hitbox touched)
	and walks up to the tagged part. Reaching 0 destroys the structure and frees its slot.
]]
function BuildService.damageStructure(instance: Instance, amount: number)
	if typeof(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return
	end
	local node: Instance? = instance
	while node and node ~= Workspace do
		if node:IsA("BasePart") and CollectionService:HasTag(node, STRUCTURE_TAG) then
			break
		end
		node = node.Parent
	end
	if not node or node == Workspace or not node:IsA("BasePart") then
		return
	end

	local health = node:GetAttribute(HEALTH_ATTRIBUTE) :: number?
	if not health or health <= 0 then
		return
	end
	local newHealth = math.max(0, health - amount)
	node:SetAttribute(HEALTH_ATTRIBUTE, newHealth)
	if newHealth <= 0 then
		BuildService.destroyStructure(node)
	end
end

function BuildService.destroyStructure(part: BasePart)
	-- Occupancy release rides the folder's ChildRemoved listener, so external
	-- :Destroy() calls behave identically.
	part:Destroy()
end

function BuildService.init()
	-- Runtime-created storage + remote (XPService pattern).
	local storage = ReplicatedStorage:FindFirstChild(BuildConfig.storageFolderName)
	if not storage then
		storage = Instance.new("Folder")
		storage.Name = BuildConfig.storageFolderName
		storage.Parent = ReplicatedStorage
	end
	template = getPanelTemplate.ensure(storage :: Folder)

	local existingFolder = Workspace:FindFirstChild(PLACED_FOLDER_NAME)
	local folder: Folder
	if existingFolder and existingFolder:IsA("Folder") then
		folder = existingFolder
	else
		folder = Instance.new("Folder")
		folder.Name = PLACED_FOLDER_NAME
		folder.Parent = Workspace
	end
	placedFolder = folder

	-- Centralized occupancy release: one listener for every structure, however it dies.
	folder.ChildRemoved:Connect(function(child)
		local slotKey = child:GetAttribute(SLOT_KEY_ATTRIBUTE)
		if typeof(slotKey) == "string" and occupied[slotKey] == child then
			occupied[slotKey] = nil
		end
	end)

	local remote = Instance.new("RemoteEvent")
	remote.Name = "PlaceStructure"
	remote.Parent = storage
	remote.OnServerEvent:Connect(onPlaceRequest)

	Players.PlayerRemoving:Connect(function(player: Player)
		lastPlacement[player] = nil
	end)

	-- One Heartbeat accumulator for every construction ramp (VitalsService pattern).
	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt: number)
		accumulated += dt
		if accumulated >= BuildConfig.rampTickInterval and #underConstruction > 0 then
			stepConstruction(accumulated)
			accumulated = 0
		elseif #underConstruction == 0 then
			accumulated = 0
		end
	end)
end

return BuildService
