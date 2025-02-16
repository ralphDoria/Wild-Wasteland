local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RobloxStateMachine = require(ReplicatedStorage:FindFirstChild("robloxstatemachine", true))

local tag = "NPC_FSM_Test"

local function handleTaggedInstances(taggedInstance)
    RobloxStateMachine.new(
        "Idle", 
        RobloxStateMachine:LoadDirectory(ReplicatedStorage:FindFirstChild("NPCtest", true).States), 
        { 
            npc = taggedInstance,
            humanoid = taggedInstance.Humanoid,
            startingPosition = taggedInstance.PrimaryPart.Position,
            player = nil
        }
    )
end

for _, taggedInstance in CollectionService:GetTagged(tag) do
    handleTaggedInstances(taggedInstance)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
    handleTaggedInstances(taggedInstance)
end)