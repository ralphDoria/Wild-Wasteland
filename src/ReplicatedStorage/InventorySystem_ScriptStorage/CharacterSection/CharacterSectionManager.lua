local ReplicatedStoarge = game:GetService("ReplicatedStorage")
local ScriptStorage = ReplicatedStoarge.RojoManaged_RS.InventorySystem_ScriptStorage
local characterSectionComponents = ScriptStorage.CharacterSection.Components
local References_Inventory = require(ScriptStorage.Components.References_Inventory_Client)
local InventoryVitalsDisplay = require(characterSectionComponents.InventoryVitalsDisplay)
local ViewportController = require(characterSectionComponents.ViewportController)
local EquipmentSlots = require(characterSectionComponents.EquipmentSlots)

export type CharacterSectionObject = {
    inventoryVitalsObject: InventoryVitalsDisplay.InventoryVitals,
    viewportControllerObject: ViewportController.ViewportController
}

local CharacterSection = {}

function CharacterSection.new(): CharacterSectionObject
    local self: CharacterSectionObject = {
        inventoryVitalsObject = InventoryVitalsDisplay.new(),
        viewportControllerObject = ViewportController.new(References_Inventory.Viewport)
    }
    EquipmentSlots.init() -- only creates equipment slots, which will be cleaned up when Inventory is destroyed when character is removed

    return self
end

function CharacterSection.ResizeGui(self: CharacterSectionObject)
    InventoryVitalsDisplay.ResizeGui(self.inventoryVitalsObject)
end

function CharacterSection.Destroy(self: CharacterSectionObject)
    InventoryVitalsDisplay.Destroy(self.inventoryVitalsObject)
    ViewportController.Destroy(self.viewportControllerObject)
end

return CharacterSection