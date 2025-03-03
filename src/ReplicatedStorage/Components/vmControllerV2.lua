local vmController = {}
vmController.__index = vmController

local AnimationController = require(ReplicatedStorage:FindFirstChild("AnimationController", true))

function vmController.new(tool : Tool)
    local self = setmetatable({}, vmController)

    self.springModule = nil --to be implemented
    self.vm = workspace.Camera:WaitForChild("viewModel")
    self.animController = AnimationController.new(vm.Animator, tool.Anims:GetChildren())

    self.init()

    return self
end

--[[
    Basically starts having the viewmodel mirror the actual character
]]
function vmController.init()
    
end

return vmController