export type WearableCategoryType = "Head" | "Torso" | "Backpack" | "Legs" | "Feet"

local WearableCategory = {}

WearableCategory.ValidWearableCategories = {"Head", "Torso", "Backpack", "Legs", "Feet"}

--[[
    This function errors if value passed is not of a valid type
]]
function WearableCategory.typeCheck(value)
    assert(typeof(value) == "string")
    local valid = false
    for _, v in WearableCategory.ValidWearableCategories do
        if tostring(value) == v then
            valid = true
        end
    end
    if not valid then
        error(tostring(value) .. " is not a valid WearableCategory attribute")
    end
end

return WearableCategory