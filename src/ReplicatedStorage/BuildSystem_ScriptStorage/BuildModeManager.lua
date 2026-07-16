--!strict
--[[
	Client build mode (docs/PLAYTEST_VERIFICATION.md → "Build system v1").

	Entry is TEMPORARY until the dedicated build item exists: the place-built
	Inventory.Hotbar.TempBuildButton toggles build mode (a UICorner with scale-1 radius on
	its innerFrame is the "active" look). While build mode is on, V/B/N are ActionManager
	TOGGLE buttons selecting Wall/Floor/Stairs — mutually exclusive via forceToggle, just
	like Gun's Aiming/Inspect pair — and while a structure is selected, MouseButton1/tap
	("Place Structure", bound Gun-Activate style) requests a placement.

	The preview is ONE reused ghost clone of the shared panel template, updated on a
	RenderStepped connection that exists only while a structure is selected. Selection is
	a RAY-MARCH through the same pure BuildMath the server validates with: the camera ray
	(stopped by the first solid hit — built structures, map geometry, terrain) collects
	every slot it passes through inside the 3x3x3 region around the HumanoidRootPart's
	cell, and the candidate closest to the root part wins (ties: first crossed). The
	ghost's Highlight turns previewInvalidColor (red) when the winning slot is occupied
	(client-side occupancy view: SlotKey attributes on the PlacedStructures folder's
	children) or unsupported (isSlotSupported — the shared "no floating pieces" probe),
	and invalid clicks aren't even sent. The ghost has CanQuery = false, so neither the
	aim raycast nor the support probe can ever hit it.

	This manager is a VIEW + request source only: it sends five scalars to the
	PlaceStructure remote and owns no authority (BuildService validates everything).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BuildConfig = require(script.Parent.Data.BuildConfig)
local BuildMath = require(script.Parent.Sim.BuildMath)
local getPanelTemplate = require(script.Parent.Components.getPanelTemplate)
local isSlotSupported = require(script.Parent.Components.isSlotSupported)
local ActionManager = require(ReplicatedStorage.RojoManaged_RS.ActionManagerSystem.ActionManager)

local PLACE_ACTION = "Place Structure"

type StructureAction = {
	actionName: string,
	kind: string,
	keyboardInput: Enum.KeyCode,
	gamepadInput: Enum.KeyCode,
	displayOrder: number,
}

-- displayOrder 10+ stays clear of the movement (0-2) and item (3-6) binds.
local STRUCTURE_ACTIONS: { StructureAction } = {
	{ actionName = "Build Wall", kind = "Wall", keyboardInput = Enum.KeyCode.V, gamepadInput = Enum.KeyCode.DPadLeft, displayOrder = 10 },
	{ actionName = "Build Floor", kind = "Floor", keyboardInput = Enum.KeyCode.B, gamepadInput = Enum.KeyCode.DPadUp, displayOrder = 11 },
	{ actionName = "Build Stairs", kind = "Stairs", keyboardInput = Enum.KeyCode.N, gamepadInput = Enum.KeyCode.DPadRight, displayOrder = 12 },
}

local player = Players.LocalPlayer :: Player

local BuildModeManager = {}

local initialized = false
local buildModeActive = false
local selectedKind: string? = nil

local innerFrame: Frame? = nil
local activeCorner: UICorner? = nil
local template: BasePart? = nil
local placeRemote: RemoteEvent? = nil

local ghost: BasePart? = nil
local ghostHighlight: Highlight? = nil
local previewConnection: RBXScriptConnection? = nil
local currentSlot: BuildMath.Slot? = nil
local currentSlotValid = false
local lastGhostSlotKey: string? = nil
local lastPlacementRequest = 0

-- Client-side occupancy view: SlotKey attribute -> occupied, maintained from the
-- replicated PlacedStructures folder so the ghost can flag taken slots without asking
-- the server. validityDirty forces a re-check when the folder changes under a
-- stationary aim (e.g. our own placement landing in the previewed slot).
local occupiedKeys: { [string]: boolean } = {}
local validityDirty = false

local function actionNameForKind(kind: string): string?
	for _, info in STRUCTURE_ACTIONS do
		if info.kind == kind then
			return info.actionName
		end
	end
	return nil
end

-- The one reused preview part. Created lazily, reparented (not recreated) per selection.
local function getGhost(): BasePart?
	if ghost then
		return ghost
	end
	local panelTemplate = template
	if not panelTemplate then
		return nil
	end
	local newGhost = panelTemplate:Clone()
	newGhost.Name = "BuildGhost"
	newGhost.Anchored = true
	newGhost.CanCollide = false
	newGhost.CanQuery = false -- the aim raycast must never hit the preview
	newGhost.CanTouch = false
	newGhost.CastShadow = false
	-- The ghost must stay OPAQUE: Roblox Highlights don't render on transparent parts
	-- (only placed structures go translucent, during their construction ramp). The
	-- Highlight (default settings, fill colored by validity) IS the preview look.
	newGhost.Transparency = 0
	local highlight = Instance.new("Highlight")
	highlight.FillColor = BuildConfig.previewColor
	highlight.Adornee = newGhost
	highlight.Parent = newGhost
	ghostHighlight = highlight
	ghost = newGhost
	return newGhost
end

local function stopPreview()
	if previewConnection then
		previewConnection:Disconnect()
		previewConnection = nil
	end
	if ghost then
		ghost.Parent = nil
	end
	currentSlot = nil
	currentSlotValid = false
	lastGhostSlotKey = nil
end

local function onPreviewStep()
	local kind = selectedKind
	local camera = Workspace.CurrentCamera
	local activeGhost = ghost
	if not kind or not camera or not activeGhost then
		return
	end
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return
	end

	local origin = camera.CFrame.Position
	local look = camera.CFrame.LookVector
	local cameraYaw = math.atan2(-look.X, -look.Z)
	local centerCell = BuildMath.cellOfPoint(BuildConfig, rootPart.Position)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	params.FilterDescendantsInstances = { camera, character :: Instance }

	-- Anything solid stops the aim ray (built structures, map geometry, terrain) —
	-- slots strictly behind the hit are unreachable. The small slack keeps a grid
	-- plane coinciding with the hit surface countable as crossed.
	local result = Workspace:Raycast(origin, look * BuildConfig.maxBuildRange, params)
	local maxDistance = if result then result.Distance + 0.25 else BuildConfig.maxBuildRange

	-- Ray-march selection: every in-region slot the ray passes through is a candidate;
	-- the one closest to the HumanoidRootPart wins (ties: first crossed).
	local slot = BuildMath.selectSlotAlongRay(BuildConfig, kind, origin, look, maxDistance, centerCell, cameraYaw, rootPart.Position)
	currentSlot = slot

	local slotKey = BuildMath.slotKey(slot)
	if slotKey ~= lastGhostSlotKey or validityDirty then
		lastGhostSlotKey = slotKey
		validityDirty = false
		activeGhost.Size = BuildMath.slotSize(BuildConfig, slot)
		activeGhost.CFrame = BuildMath.slotToCFrame(BuildConfig, slot)
		currentSlotValid = not occupiedKeys[slotKey] and isSlotSupported(slot)
		if ghostHighlight then
			ghostHighlight.FillColor = if currentSlotValid then BuildConfig.previewColor else BuildConfig.previewInvalidColor
		end
	end
end

local function requestPlacement()
	local kind = selectedKind
	local slot = currentSlot
	local remote = placeRemote
	if not kind or not slot or not remote or not currentSlotValid then
		return
	end
	local now = os.clock()
	if now - lastPlacementRequest < BuildConfig.placementCooldown then
		return
	end
	lastPlacementRequest = now
	remote:FireServer(kind, slot.x, slot.y, slot.z, slot.orient)
end

local function bindPlaceAction()
	if ActionManager.isBinded(PLACE_ACTION) then
		return
	end
	ActionManager.bindAction(
		PLACE_ACTION,
		function()
			local function onActivated()
				requestPlacement()
			end
			local function noop() end
			return onActivated, noop, noop
		end,
		Enum.UserInputType.MouseButton1,
		Enum.KeyCode.ButtonR2,
		13,
		nil, -- momentary, Gun-Activate style
		nil,
		"" -- icon id comes later
	)
end

local function deselectStructure(kind: string)
	if selectedKind ~= kind then
		return -- stale deactivation from a forceToggle during a selection switch
	end
	selectedKind = nil
	stopPreview()
	if ActionManager.isBinded(PLACE_ACTION) then
		ActionManager.unbindAction(PLACE_ACTION)
	end
end

local function selectStructure(kind: string)
	-- Only one structure selectable at a time: switch off the others FIRST (their
	-- onDeactivated runs deselectStructure and tears the old preview down; forceToggle
	-- no-ops on already-off toggles).
	for _, info in STRUCTURE_ACTIONS do
		if info.kind ~= kind then
			ActionManager.forceToggle(info.actionName, false)
		end
	end

	selectedKind = kind
	local activeGhost = getGhost()
	local camera = Workspace.CurrentCamera
	if activeGhost and camera then
		activeGhost.Parent = camera
	end
	lastGhostSlotKey = nil
	if not previewConnection then
		previewConnection = RunService.RenderStepped:Connect(onPreviewStep)
	end
	bindPlaceAction()
end

local function bindStructureActions()
	for _, info in STRUCTURE_ACTIONS do
		if ActionManager.isBinded(info.actionName) then
			continue
		end
		ActionManager.bindAction(
			info.actionName,
			function()
				local function onActivated()
					selectStructure(info.kind)
				end
				local function onDeactivated()
					deselectStructure(info.kind)
				end
				local function onUnbind()
					deselectStructure(info.kind)
				end
				return onActivated, onDeactivated, onUnbind
			end,
			info.keyboardInput,
			info.gamepadInput,
			info.displayOrder,
			false, -- toggle button, starts unselected
			nil,
			"" -- icon ids come later
		)
	end
end

local function setBuildMode(on: boolean)
	if buildModeActive == on then
		return
	end
	buildModeActive = on

	if on then
		local frame = innerFrame
		if frame then
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = frame
			activeCorner = corner
		end
		bindStructureActions()
	else
		-- Deselect first (tears down preview + the place bind), then drop the keybinds.
		local kind = selectedKind
		if kind then
			local actionName = actionNameForKind(kind)
			if actionName then
				ActionManager.forceToggle(actionName, false)
			end
		end
		for _, info in STRUCTURE_ACTIONS do
			if ActionManager.isBinded(info.actionName) then
				ActionManager.unbindAction(info.actionName)
			end
		end
		if activeCorner then
			activeCorner:Destroy()
			activeCorner = nil
		end
	end
end

local function onCharacterAdded(character: Model)
	-- Build mode doesn't survive death (MovementActionsInitializer pattern) ...
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Once(function()
			setBuildMode(false)
		end)
	end
	-- ... and equipping a tool while placing hands MouseButton1 back to the weapon
	-- (Gun/Melee bind their own Activate/Swing on equip — avoid the tug-of-war).
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and selectedKind then
			local actionName = actionNameForKind(selectedKind :: string)
			if actionName then
				ActionManager.forceToggle(actionName, false)
			end
		end
	end)
end

function BuildModeManager.init()
	assert(RunService:IsClient(), "BuildModeManager can only be used on the client!")
	if initialized then
		return
	end
	initialized = true

	-- The temporary entry button is place-built and still WIP: degrade to inert (warn,
	-- no errors) if any piece hasn't been added to the place yet.
	local playerGui = player:WaitForChild("PlayerGui")
	local inventoryGui = playerGui:WaitForChild("Inventory", 10)
	local hotbar = inventoryGui and inventoryGui:WaitForChild("Hotbar", 10)
	local buildButton = hotbar and hotbar:WaitForChild("TempBuildButton", 10)
	if not buildButton then
		warn("[BuildModeManager] Inventory.Hotbar.TempBuildButton not found — build mode disabled")
		return
	end
	local foundInnerFrame = buildButton:WaitForChild("innerFrame", 10)
	if not foundInnerFrame or not foundInnerFrame:IsA("Frame") then
		warn("[BuildModeManager] TempBuildButton.innerFrame not found — build mode disabled")
		return
	end
	innerFrame = foundInnerFrame

	-- Server-published template + remote (BuildService.init creates both).
	template = getPanelTemplate.waitForTemplate()
	local storage = ReplicatedStorage:WaitForChild(BuildConfig.storageFolderName, 10)
	local remote = storage and storage:WaitForChild("PlaceStructure", 10)
	if not template or not remote or not remote:IsA("RemoteEvent") then
		warn("[BuildModeManager] BuildService remote/template missing — build mode disabled")
		return
	end
	placeRemote = remote

	-- Occupancy view: mirror the replicated placed-structure folder into a SlotKey set
	-- (attributes are set before parenting, so ChildAdded always sees them).
	local placedFolder = Workspace:WaitForChild(BuildConfig.placedFolderName, 10)
	if not placedFolder then
		warn("[BuildModeManager] Placed-structures folder missing — build mode disabled")
		return
	end
	local function onPlacedChanged(child: Instance, occupiedNow: boolean)
		local slotKey = child:GetAttribute("SlotKey")
		if typeof(slotKey) == "string" then
			occupiedKeys[slotKey] = if occupiedNow then true else nil
			validityDirty = true
		end
	end
	placedFolder.ChildAdded:Connect(function(child)
		onPlacedChanged(child, true)
	end)
	placedFolder.ChildRemoved:Connect(function(child)
		onPlacedChanged(child, false)
	end)
	for _, child in placedFolder:GetChildren() do
		onPlacedChanged(child, true)
	end

	-- Toggle from the button: prefer a real GuiButton inside innerFrame (TouchBackpackSlot
	-- convention), fall back to presses anywhere on the frame.
	local clickable = foundInnerFrame:FindFirstChildWhichIsA("GuiButton", true)
	if clickable then
		clickable.Activated:Connect(function()
			setBuildMode(not buildModeActive)
		end)
	else
		buildButton.InputBegan:Connect(function(inputObject: InputObject)
			if
				inputObject.UserInputType == Enum.UserInputType.MouseButton1
				or inputObject.UserInputType == Enum.UserInputType.Touch
			then
				setBuildMode(not buildModeActive)
			end
		end)
	end

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

return BuildModeManager
