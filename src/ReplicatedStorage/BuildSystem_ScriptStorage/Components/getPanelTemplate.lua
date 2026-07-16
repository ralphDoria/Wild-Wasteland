--!strict
--[[
	Resolves the structure panel template both sides clone from. Canonical location:
	ReplicatedStorage[storageFolderName][templateName] — the place-built RustyMetalSheet
	union lives there. If it's ever missing (fresh place, renamed piece), the SERVER
	generates a placeholder Part of BuildConfig.panelSize in the same spot in
	BuildService.init, so the system still runs and the client never needs to know which
	source won.
]]

local BuildConfig = require(script.Parent.Parent.Data.BuildConfig)

local getPanelTemplate = {}

-- Server: make sure the canonical template exists under the storage folder and return
-- it. Idempotent (the place-built union or a previous init's placeholder is reused).
function getPanelTemplate.ensure(storage: Folder): BasePart
	local existing = storage:FindFirstChild(BuildConfig.templateName)
	if existing and existing:IsA("BasePart") then
		existing.Anchored = true
		return existing
	end

	warn(`[getPanelTemplate] {BuildConfig.templateName} missing from {storage:GetFullName()} — generating a placeholder panel`)
	local part = Instance.new("Part")
	part.Name = BuildConfig.templateName
	part.Size = BuildConfig.panelSize
	part.Material = Enum.Material.Concrete
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.Parent = storage
	return part
end

-- Client: wait for the template (nil + warn on timeout so callers can degrade
-- gracefully instead of erroring).
function getPanelTemplate.waitForTemplate(timeout: number?): BasePart?
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local storage = ReplicatedStorage:WaitForChild(BuildConfig.storageFolderName, timeout or 10)
	if not storage then
		warn("[getPanelTemplate] BuildSystem storage folder never replicated — is BuildService running?")
		return nil
	end
	local template = storage:WaitForChild(BuildConfig.templateName, timeout or 10)
	if not template or not template:IsA("BasePart") then
		warn("[getPanelTemplate] Structure panel template missing from the storage folder")
		return nil
	end
	return template
end

return getPanelTemplate
