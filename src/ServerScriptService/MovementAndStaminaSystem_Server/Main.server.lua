--!strict
--[[
	Movement intent receiver (Tier 3 Batch V2 — kills BUGS.md C2).

	The old ChangeHumanoidWalkSpeed handler set a CLIENT-SUPPLIED humanoid's WalkSpeed to a
	CLIENT-SUPPLIED number (speedhacks, freezing other players, NPC tampering). It is gone;
	the Studio-side remote is now inert if a client fires it.

	Clients now send what they WANT to do — a movement mode name — and the server:
	- validates the mode against Data/Config.speed ("Default"/"Sprint"/"Crouch"),
	- applies the WalkSpeed it looks up itself, to the SENDER's own humanoid only,
	- gates Sprint on server-side stamina (see VitalsService).

	The MovementIntent RemoteEvent is created here at runtime (the Studio place only holds
	the legacy remotes) and parented next to them for the clients to WaitForChild.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VitalsService = require(script.Parent.Parent.VitalsSystem_Server.VitalsService)
VitalsService.init() -- idempotent; guards against script-start ordering

local MovementAndStaminaSystem_Storage = ReplicatedStorage:WaitForChild("MovementAndStaminaSystem_Storage")
local remotesFolder = MovementAndStaminaSystem_Storage:WaitForChild("Remotes")

local movementIntentRemote = Instance.new("RemoteEvent")
movementIntentRemote.Name = "MovementIntent"
movementIntentRemote.Parent = remotesFolder

movementIntentRemote.OnServerEvent:Connect(function(player: Player, mode: unknown)
	if type(mode) ~= "string" then
		return
	end
	-- VitalsService re-validates the mode against Config.speed and owns the state.
	VitalsService.setMovementIntent(player, mode)
end)
