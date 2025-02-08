local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local Transition = RobloxStateMachine.Transition
local Died = Transition.new("Dead") --Changes the state to changing when the requirements for it are met

function Died:OnDataChanged(data) --called every frame
    local humanoid = data.humanoid

    return humanoid.Health <= 0
end

return Died