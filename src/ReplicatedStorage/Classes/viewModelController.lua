local viewModelController = {}
viewModelController.__index = viewModelController

function viewModelController.new(viewModel : Model)
    local self = {}
    --self.viewModel = 
    self.connections = {}
    return setmetatable(self, viewModelController)
end

function viewModelController:Intiialize()
    --fill the self.connections table
end

function viewModelController:enable()
    --use RunService:BindToRenderStep(bindName : String, Enum.RenderPriority, functionToBind)
end

function viewModelController:disable()
    --use RunService:UnbindFromRenderStep(bindName : String)
end

function viewModelController:hideToolInstances()
    --use LocalTransparencyModifier
end

function viewModelController:unhideToolInstances()
    --use LocalTransparencyModifier
end

function viewModelController:update()
    --[[
        -Procedurally animated bobbing effect and ADS
    ]]
end

function viewModelController:destroy()

end

return viewModelController