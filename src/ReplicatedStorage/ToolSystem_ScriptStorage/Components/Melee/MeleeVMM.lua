local Players = game:GetService("Players")
local ViewmodelManager = require("../Shared/ViewmodelManager")

local MeleeVMM = {}

function MeleeVMM.initialize()
    
end

local function foo(self : ViewmodelManager.ViewmodelManager, tool : Tool)
    assert(tool:HasTag("Melee"), "This module is only for melee tools.")
    local vmTool = self.ToolToVMToolMapping[tool]
    local trail = tool:FindFirstChildWhichIsA("Trail", true)
    local vmTrail = vmTool:FindFirstChildWhichIsA("Trail", true)
    local isFirstPerson : boolean = Players.LocalPlayer.Character.Torso.LocalTransparencyModifier >= 1
    if isFirstPerson then
        vmTrail.Transparency = NumberSequence.new(0.5)
        trail.Transparency = NumberSequence.new(1)
    else
        vmTrail.Transparency = NumberSequence.new(1)
        trail.Transparency = NumberSequence.new(0.5)
    end
end

function MeleeVMM.ConnectTrailsTransparencyUpdater(self : ViewmodelManager.ViewmodelManager, tool : Tool)
    foo(self, tool) --initial check
    table.insert(
        self.connections,
        Players.LocalPlayer.Character.Torso:GetPropertyChangedSignal("LocalTransparencyModifier"):Connect(function()
            foo(self, tool)
        end)
    )
end

return MeleeVMM