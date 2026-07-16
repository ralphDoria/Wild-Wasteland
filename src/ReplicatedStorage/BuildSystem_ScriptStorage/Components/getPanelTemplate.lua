--!strict
--[[
	Resolves the structure panel template both sides clone from. Canonical location:
	ReplicatedStorage[storageFolderName][templateName] — the SERVER puts it there in
	BuildService.init (a clone of the user's real union from
	ReplicatedStorage[assetsFolderName][templateName] if it exists, otherwise a generated
	placeholder Part of BuildConfig.panelSize). The client just waits for that one spot,
	so it never needs to know which source won.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildConfig = require(script.Parent.Parent.Data.BuildConfig)

local getPanelTemplate = {}

-- Server: make sure the canonical template exists under the runtime storage folder and
-- return it. Idempotent (re-init reuses the existing child).
function getPanelTemplate.ensure(storage: Folder): BasePart
	local existing = storage:FindFirstChild(BuildConfig.templateName)
	if existing and existing:IsA("BasePart") then
		return existing
	end

	local template: BasePart
	local assetsFolder = ReplicatedStorage:FindFirstChild(BuildConfig.assetsFolderName)
	local realUnion = assetsFolder and assetsFolder:FindFirstChild(BuildConfig.templateName)
	if realUnion and realUnion:IsA("BasePart") then
		template = realUnion:Clone()
	else
		-- Placeholder until the real union lands (see BuildConfig header).
		local part = Instance.new("Part")
		part.Size = BuildConfig.panelSize
		part.Material = Enum.Material.Concrete
		part.TopSurface = Enum.SurfaceType.Smooth
		part.BottomSurface = Enum.SurfaceType.Smooth
		template = part
	end
	template.Name = BuildConfig.templateName
	template.Anchored = true
	template.Parent = storage
	return template
end

-- Client: wait for the server-published template (nil + warn on timeout so callers can
-- degrade gracefully instead of erroring).
function getPanelTemplate.waitForTemplate(timeout: number?): BasePart?
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
