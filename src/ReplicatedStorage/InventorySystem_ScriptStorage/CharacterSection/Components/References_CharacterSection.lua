local References_Inventory = require("./../../Components/References_Inventory")
local References_CharacterSection = {}

References_CharacterSection.InventoryScreenGui = References_Inventory.InventoryScreenGui

-- TODO: set loading screen text to waiting for Vitals gui
References_CharacterSection.Vitals = References_Inventory.CharacterSection:WaitForChild("Vitals"):: Frame
-- TODO: set loading screen text to waiting for Character Viewport gui
References_CharacterSection.Viewport = References_Inventory.CharacterSection:WaitForChild("ViewportFrame"):: ViewportFrame
References_CharacterSection.EquipmentSlots = References_Inventory.CharacterSection:WaitForChild("EquipmentSlots"):: Frame

return References_CharacterSection