local tag = "npc_mutantRoach"

local targetPart = game.Workspace.npc_roach_test.targetLocation

local CollectionService = game:GetService("CollectionService")

local function mutantRoachTagHandler(taggedInstance)
    local humanoid = taggedInstance:FindFirstChildOfClass("Humanoid")
    while true do
        print("calling moveTo")
        humanoid:MoveTo(targetPart.Position, targetPart)
        task.wait(1)
    end
end



--<<EXECUTING CODE BELOW>>
for _, taggedInstance in CollectionService:GetTagged(tag) do
    mutantRoachTagHandler(taggedInstance)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
    mutantRoachTagHandler(taggedInstance)
end)