local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local State = RobloxStateMachine.State
local Idle = State.new("Idle")
Idle.Transitions = {
    require(ReplicatedStorage:FindFirstChild("NPCtest", true).Transitions.SawPlayer),
    require(ReplicatedStorage:FindFirstChild("NPCtest", true).Transitions.Died)
}

function Idle:OnEnter(data)
    -- print("Entered Idle!")
    local humanoid = data.humanoid
    local startingPosition = data.startingPosition

    humanoid:MoveTo(startingPosition)
end

return Idle