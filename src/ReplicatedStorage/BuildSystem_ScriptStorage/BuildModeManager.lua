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
	RenderStepped connection that exists only while a structure is selected. Snapping runs
	the same pure BuildMath the server validates with, so what the ghost shows is exactly
	what the server will build. The ghost has CanQuery = false, so the aim raycast can
	never hit it.

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
local previewConnection: RBXScriptConnection? = nil
local currentSlot: BuildMath.Slot? = nil
local lastGhostSlotKey: string? = nil
local lastPlacementRequest = 0

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
	newGhost.Color = BuildConfig.previewColor
	newGhost.Transparency = BuildConfig.previewTransparency
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
	lastGhostSlotKey = nil
end

local function onPreviewStep()
	local kind = selectedKind
	local camera = Workspace.CurrentCamera
	local activeGhost = ghost
	if not kind or not camera or not activeGhost then
		return
	end

	local origin = camera.CFrame.Position
	local look = camera.CFrame.LookVector

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	local exclude: { Instance } = { camera }
	if player.Character then
		table.insert(exclude, player.Character)
	end
	params.FilterDescendantsInstances = exclude

	-- Hits snap to the NEAR side of the surface (the small pull toward the camera);
	-- no hit means air-building at max range, Fortnite-style.
	local result = Workspace:Raycast(origin, look * BuildConfig.maxBuildRange, params)
	local aimPoint = if result then result.Position - look * 0.1 else origin + look * BuildConfig.maxBuildRange

	local cameraYaw = math.atan2(-look.X, -look.Z)
	local slot = BuildMath.worldToSlot(BuildConfig, kind, aimPoint, cameraYaw)
	currentSlot = slot

	local slotKey = BuildMath.slotKey(slot)
	if slotKey ~= lastGhostSlotKey then
		lastGhostSlotKey = slotKey
		activeGhost.Size = BuildMath.slotSize(BuildConfig, slot)
		activeGhost.CFrame = BuildMath.slotToCFrame(BuildConfig, slot)
	end
end

local function requestPlacement()
	local kind = selectedKind
	local slot = currentSlot
	local remote = placeRemote
	if not kind or not slot or not remote then
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
