local characterSectionComponents = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.CharacterSection.Components
local InventoryVitalsDisplay = require(characterSectionComponents.VitalsDisplay)
local ViewportController = require(characterSectionComponents.ViewportController)
local EquipmentSlots = require(characterSectionComponents.EquipmentSlots)

local CharacterSection = {}

function CharacterSection.ResizeGui()
    InventoryVitalsDisplay.ResizeGui()
end

function CharacterSection.init()
    InventoryVitalsDisplay.init()
    ViewportController.init()
    EquipmentSlots.init()
end

return CharacterSection