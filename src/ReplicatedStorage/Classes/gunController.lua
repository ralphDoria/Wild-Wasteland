local gunController = {}
gunController.__index = gunController

function gunController.new()
    local self = {}
    
    return setmetatable(self, gunController)
end

function gunController:destroy()
end

return gunController