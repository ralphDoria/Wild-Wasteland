local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local State = RobloxStateMachine.State
local Attack = State.new("Attack")
Attack.Transitions = {
    require(ReplicatedStorage:FindFirstChild("NPCtest", true).Transitions.OffAttackRange),
    require(ReplicatedStorage:FindFirstChild("NPCtest", true).Transitions.Died)
}

function Attack:OnEnter()
    print("Entered Attack!")
    self.timer = 0
end

function Attack:OnHeartbeat(data, deltaTime)
    local player : Player = data.player
    local character = player and player.Character
    local plrHumanoid : Humanoid? = character and character:FindFirstChildOfClass("Humanoid")
    if not plrHumanoid then return end

    if self.timer < 1.5 then
        self.timer += deltaTime
        return
    end

    self.timer = 0
    plrHumanoid:TakeDamage(20)
end

return Attack