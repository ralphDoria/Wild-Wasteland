local References_CharacterSection = require("./Components/References_CharacterSection")
local Vitals = require("./Components/Vitals")

local CharacterSection = {}

CharacterSection.Connections = {}

function CharacterSection.resizegui()
    local x = References_CharacterSection.InventoryScreenGui.AbsoluteSize.X
    local y = References_CharacterSection.InventoryScreenGui.AbsoluteSize.Y



end

function CharacterSection.init()
    Vitals.init()
    table.insert(
        CharacterSection.Connections,
        References_CharacterSection.InventoryScreenGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(Vitals.ResizeGui)
    )
    -- EquipmentSlots.init()
end

return CharacterSection