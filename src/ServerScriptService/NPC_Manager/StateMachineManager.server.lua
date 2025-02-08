local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))

local tag = "NPC_FSM_Test"
local npc = CollectionService:GetTagged(tag)[1]

RobloxStateMachine.new(
    "Idle", 
    RobloxStateMachine:LoadDirectory(ReplicatedStorage:FindFirstChild("NPCtest", true).States), 
    { 
        npc = npc,
        humanoid = npc.Humanoid,
        startingPosition = npc.PrimaryPart.Position,
        player = nil
    }
)