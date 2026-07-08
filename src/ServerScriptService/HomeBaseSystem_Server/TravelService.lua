--!nonstrict
--[[
	Server-authoritative transport between a player's base and the ONE shared wasteland. Travel
	is independent per player: each request starts that player's own intermission, then the
	server moves their character. The client NEVER sends a destination — only an intent
	("Wasteland" | "Home"). This is what finally kills the C5 exploit
	(SpawnAndDeathSystem_Server/Main.server.lua's MoveCharacterToSpawn, which PivotTo's to a
	client-supplied CFrame): once travel is routed through here, that RemoteFunction should be
	removed and any legit spawn placement done server-side.

	Loop state (Types.LoopState) is owned here and gates legality: you can only depart from
	InBunker and only return from InWasteland; a request while already traveling is ignored.

	SCAFFOLD STATUS: state machine, validation, and the intermission timeline are real. The
	actual character freeze/teleport is stubbed to a PivotTo + attribute; wire the intermission
	UI (fade/loading) via the TravelStateChanged remote on the client. Arrival point reads a
	named workspace Part (HomeBaseConfig.wasteland.arrivalPartName) that must exist in the place.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HomeBaseConfig = require(ReplicatedStorage.RojoManaged_RS.HomeBaseSystem_ScriptStorage.Data.HomeBaseConfig)
local HomeBaseService = require(script.Parent.HomeBaseService)

local TravelService = {}

-- player -> LoopState. Absence == "InBunker" default once their base exists.
local loopState: { [Player]: string } = {}
local remotes: { [string]: RemoteEvent }? = nil

-- ── Helpers ────────────────────────────────────────────────────────────────────────────────────

local function setState(player: Player, state: string)
	loopState[player] = state
	if remotes then
		remotes.TravelStateChanged:FireClient(player, state)
	end
end

local function getAliveCharacter(player: Player): Model?
	local character = player.Character
	if not character then return nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil end
	if not character.PrimaryPart then return nil end
	return character
end

local function wastelandArrivalCFrame(): CFrame?
	local part = workspace:FindFirstChild(HomeBaseConfig.wasteland.arrivalPartName, true)
	if not part or not part:IsA("BasePart") then
		warn(`[TravelService] wasteland arrival part '{HomeBaseConfig.wasteland.arrivalPartName}' missing`)
		return nil
	end
	return part.CFrame + Vector3.new(0, 5, 0)
end

-- SCAFFOLD: freeze the character for the intermission, then move it. Replace with the real
-- freeze (anchor HRP / disable controls) + a fade so the teleport is unseen.
local function moveCharacterTo(character: Model, destination: CFrame)
	local hrp = character.PrimaryPart
	if hrp then
		hrp.Anchored = true
	end
	character:PivotTo(destination)
	if hrp then
		hrp.Anchored = false
	end
end

-- ── Core transitions ───────────────────────────────────────────────────────────────────────────

local function travelToWasteland(player: Player)
	if loopState[player] ~= "InBunker" then
		return -- can only depart from the bunker; ignore double-fire / mid-travel spam
	end
	local character = getAliveCharacter(player)
	local destination = wastelandArrivalCFrame()
	if not character or not destination then
		return
	end
	setState(player, "TravelingOut")
	task.delay(HomeBaseConfig.travel.toWastelandSeconds, function()
		local char = getAliveCharacter(player)
		if not char or loopState[player] ~= "TravelingOut" then
			return -- died/left/cancelled during the intermission
		end
		moveCharacterTo(char, destination)
		setState(player, "InWasteland")
	end)
end

local function travelHome(player: Player)
	if loopState[player] ~= "InWasteland" then
		return
	end
	local character = getAliveCharacter(player)
	local entry = HomeBaseService.getEntryCFrame(player)
	if not character or not entry then
		return
	end
	setState(player, "TravelingHome")
	task.delay(HomeBaseConfig.travel.toHomeSeconds, function()
		local char = getAliveCharacter(player)
		if not char or loopState[player] ~= "TravelingHome" then
			return
		end
		moveCharacterTo(char, entry)
		setState(player, "InBunker")
	end)
end

-- ── Public interface ───────────────────────────────────────────────────────────────────────────

-- Called once by Main after a player's base exists: place them home and mark InBunker.
function TravelService.placeInBunker(player: Player)
	local character = getAliveCharacter(player)
	local entry = HomeBaseService.getEntryCFrame(player)
	if character and entry then
		moveCharacterTo(character, entry)
	end
	setState(player, "InBunker")
end

function TravelService.getState(player: Player): string?
	return loopState[player]
end

function TravelService.cleanup(player: Player)
	loopState[player] = nil
end

-- Wire the RequestTravel remote (intent-only, fully validated here).
function TravelService.init(remoteMap: { [string]: RemoteEvent })
	remotes = remoteMap
	remoteMap.RequestTravel.OnServerEvent:Connect(function(player: Player, intent: any)
		if type(intent) ~= "string" then
			return
		end
		if intent == "Wasteland" then
			travelToWasteland(player)
		elseif intent == "Home" then
			travelHome(player)
		end
		-- any other value is ignored — no client-supplied destination ever
	end)
end

return TravelService
