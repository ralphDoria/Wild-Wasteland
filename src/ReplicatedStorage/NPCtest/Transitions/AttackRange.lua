local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local Transition = RobloxStateMachine.Transition
local AttackRange = Transition.new("Attack") --Changes the state to changing when the requirements for it are met

function AttackRange:OnDataChanged(data) --called every frame
    local npc = data.npc
    local npcPosition = npc.PrimaryPart.Position
    local player = data.player
    local playerPosition = player.Character.PrimaryPart.Position

    local distance = (npcPosition - playerPosition).Magnitude

    if distance < 5 then
        return true
    else
        return false
    end
end

return AttackRange