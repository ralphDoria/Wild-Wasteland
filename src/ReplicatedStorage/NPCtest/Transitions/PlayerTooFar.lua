local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local Transition = RobloxStateMachine.Transition
local PlayerTooFar = Transition.new("Idle") --Changes the state to changing when the requirements for it are met

function PlayerTooFar:OnDataChanged(data) --called every frame
    local npc = data.npc
    local npcPosition = npc.PrimaryPart.Position
    local player = data.player
    local playerPosition = player.Character.PrimaryPart.Position

    local distance = (npcPosition - playerPosition).Magnitude

    if distance > 50 then
        return true
    else
        return false
    end
end

return PlayerTooFar