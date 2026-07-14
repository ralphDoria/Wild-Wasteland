--!strict
--[[
	Persistence config for the item system (consumed by ItemSerializer).

	attributeWhitelist: which tool attributes survive a serialize→deserialize round-trip;
	everything else is presentation and is rebuilt from the ToolCatalog clone. Keyed by the
	tool's `Type` attribute (see ToolCatalog); unknown types fall back to `default`.
]]

local ItemPersistence = {}

ItemPersistence.attributeWhitelist = {
	default = { "Quantity" },
	Stackable = { "Quantity" },
	Gun = { "Quantity", "Ammo", "AmmoReserve" },
} :: { [string]: { string } }

return ItemPersistence
