local ItemGroup = {}
ItemGroup.__index = ItemGroup

function ItemGroup.new()
    local self = {}

    setmetatable(self, ItemGroup)
    return self
end

return ItemGroup