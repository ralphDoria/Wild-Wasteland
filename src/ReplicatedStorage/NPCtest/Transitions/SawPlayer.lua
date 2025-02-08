local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))
local Transition = RobloxStateMachine.Transition
local SawPlayer = Transition.new("Chasing") --Changes the state to changing when the requirements for it are met

function SawPlayer:OnDataChanged(data) --called every frame
    local npc = data.npc
    local npcPosition = npc.PrimaryPart.Position

    for _, player : Player in Players:GetPlayers() do
        local character = player.Character

        if not character then --character may be dead or loading, so ignore for this frame
            continue
        end

        local playerPosition = character.PrimaryPart.Position
        local distance = (npcPosition-playerPosition).Magnitude

        if distance < 20 then
            data.player = player
            return true
        end
    end

    return false
end

return SawPlayer