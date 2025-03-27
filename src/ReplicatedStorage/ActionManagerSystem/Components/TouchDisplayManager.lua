local RunService = game:GetService("RunService")
local TouchDisplay = 

local TouchDisplayManager = {
    _initialized = false
}

function TouchDisplayManager._initialize()
    assert(not TouchDisplayManager._initialized, "ActionManager already initialized!")
    assert(RunService:IsClient(), "ActionManager can only be used on the client!")
    TouchDisplayManager._initialized = true
end

TouchDisplayManager._initialize()

return TouchDisplayManager