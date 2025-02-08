local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local State = RobloxStateMachine.State
local Dead = State.new("Dead")

function Dead:OnEnter(data)
    print("Entered Dead!")
    local npc = data.npc

    Debris:AddItem(npc, 5)
end

return Dead