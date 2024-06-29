local ViewModelController = {}
ViewModelController.__index = ViewModelController

function ViewModelController.new(viewModel : Model)
    local self = {}
    --self.viewModel = 
    self.connections = {}
    return setmetatable(self, ViewModelController)
end

function ViewModelController:Intiialize()
    --fill the self.connections table
end

function ViewModelController:enable()
    --use RunService:BindToRenderStep(bindName : String, Enum.RenderPriority, functionToBind)
end

function ViewModelController:disable()
    --use RunService:UnbindFromRenderStep(bindName : String)
end

function ViewModelController:hideToolInstances()
    --use LocalTransparencyModifier
end

function ViewModelController:unhideToolInstances()
    --use LocalTransparencyModifier
end

function ViewModelController:update()
    --[[
        -Procedurally animated bobbing effect and ADS
    ]]
end

function ViewModelController:destroy()

end

return ViewModelController