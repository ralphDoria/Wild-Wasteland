local characterSectionComponents = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.CharacterSection.Components
local Vitals = require(characterSectionComponents.Vitals)
local ViewportController = require(characterSectionComponents.ViewportController)
local EquipmentSlots = require(characterSectionComponents.EquipmentSlots)

local CharacterSection = {}

function CharacterSection.ResizeGui()
    Vitals.ResizeGui()
end

function CharacterSection.init()
    Vitals.init()
    ViewportController.init()
    EquipmentSlots.init()
end

return CharacterSection