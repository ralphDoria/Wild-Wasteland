--!strict
--[[
	Pure item (de)serialization for inventory/storage persistence.

	Tools are ToolCatalog entries keyed by name, so an item round-trips as
	{ tag = <toolName>, quantity = n, attributes = {<whitelisted attrs>} }. Serialize reads a
	Tool; deserialize clones the catalog model back via an INJECTED spawn function (the server's
	`ServerSpawnTool` bindable) so this module stays free of server-only globals and is directly
	TestEZ-testable (see tests/specs/ItemSerializer.spec.lua).

	The canonical attribute whitelist lives in Data/ItemPersistence.
]]

-- A single persisted item: catalog name + stack size + a whitelisted attribute bag
-- (e.g. a gun's ammo, a stackable's Quantity). Rehydrated by cloning the ToolCatalog entry.
export type StoredItem = {
	tag: string, -- ToolCatalog key (tool name)
	quantity: number,
	attributes: { [string]: any },
}

local ItemSerializer = {}

-- Pick the attribute whitelist for a tool from its `Type` attribute, falling back to default.
local function whitelistFor(tool: Instance, whitelistByType: { [string]: { string } }): { string }
	local toolType = tool:GetAttribute("Type")
	if typeof(toolType) == "string" and whitelistByType[toolType] then
		return whitelistByType[toolType]
	end
	return whitelistByType.default or {}
end

-- Tool -> StoredItem. Only whitelisted attributes are persisted.
function ItemSerializer.serialize(tool: Instance, whitelistByType: { [string]: { string } }): StoredItem
	local attributes: { [string]: any } = {}
	for _, attrName in whitelistFor(tool, whitelistByType) do
		local value = tool:GetAttribute(attrName)
		if value ~= nil then
			attributes[attrName] = value
		end
	end
	local quantity = tool:GetAttribute("Quantity")
	return {
		tag = tool.Name,
		quantity = if typeof(quantity) == "number" then quantity else 1,
		attributes = attributes,
	}
end

-- Basic shape guard so a corrupt/exploited persisted entry can't crash deserialize.
function ItemSerializer.isValidEntry(entry: any): boolean
	if type(entry) ~= "table" then return false end
	if type(entry.tag) ~= "string" or entry.tag == "" then return false end
	if type(entry.quantity) ~= "number" or entry.quantity ~= entry.quantity or entry.quantity < 0 then return false end
	if type(entry.attributes) ~= "table" then return false end
	return true
end

-- StoredItem -> Tool. `spawn(toolName, parent) -> Instance?` is injected (ServerSpawnTool).
-- Returns nil if the entry is malformed or the catalog has no such tool.
function ItemSerializer.deserialize(
	entry: StoredItem,
	spawn: (toolName: string, parent: Instance) -> Instance?,
	parent: Instance
): Instance?
	if not ItemSerializer.isValidEntry(entry) then
		warn("[ItemSerializer] rejected malformed stored item entry")
		return nil
	end
	local tool = spawn(entry.tag, parent)
	if not tool then
		return nil
	end
	tool:SetAttribute("Quantity", entry.quantity)
	for attrName, value in entry.attributes do
		tool:SetAttribute(attrName, value)
	end
	return tool
end

return ItemSerializer
