export type EquipmentCategory = "Head" | "Torso" | "Backpack" | "Legs" | "Feet"

local Type_Equipment = {}

Type_Equipment.validWearableCategories = {"Head", "Torso", "Backpack", "Legs", "Feet"}

--[[
    This function errors if value passed is not of a valid type
]]
function Type_Equipment.typeCheck(value)
    assert(typeof(value) == "string")
    local valid = false
    for _, v in Type_Equipment.validWearableCategories do
        if tostring(value) == v then
            valid = true
        end
    end
    if not valid then
        error(tostring(value) .. " is not a valid WearableCategory attribute")
    end
end

return Type_Equipment