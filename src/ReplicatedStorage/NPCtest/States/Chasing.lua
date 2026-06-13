local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local State = RobloxStateMachine.State
local Chasing = State.new("Chasing")
Chasing.Transitions = {
    require(ReplicatedStorage:FindFirstChild("NPCtest", true).Transitions.PlayerTooFar),
    require(ReplicatedStorage:FindFirstChild("NPCtest", true).Transitions.AttackRange),
    require(ReplicatedStorage:FindFirstChild("NPCtest", true).Transitions.Died)
}

function Chasing:OnEnter()
    print("Entered Chasing!")
end

function Chasing:OnHeartbeat(data)
    local player = data.player
    local humanoid = data.humanoid
    local character = player and player.Character
    if not character or not character.PrimaryPart then return end
    local playerPosition = character.PrimaryPart.Position

    humanoid:MoveTo(playerPosition)
end

return Chasing