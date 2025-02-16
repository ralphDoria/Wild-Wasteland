local Slot = {}
Slot.__index = Slot

function Slot.new(tool : Tool)
    local self = {
        type = tool:GetAttribute("Type")
    }
    self = setmetatable({}, Slot)
    return self
end

function Slot:destroy()

end

return Slot