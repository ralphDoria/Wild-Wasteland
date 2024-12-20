local tag = "npc_mutantRoach"
local targetPart = game.Workspace.npc_roach_test.targetLocation
local CollectionService = game:GetService("CollectionService")
local mutantRoach = require(script.Parent.mutantRoach)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)

local function mutantRoachTagHandler(taggedInstance)
    local roach = mutantRoach.new(taggedInstance)
    --roach:turnOn()
end

--<<EXECUTING CODE BELOW>>
for _, taggedInstance in CollectionService:GetTagged(tag) do
    mutantRoachTagHandler(taggedInstance)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
    mutantRoachTagHandler(taggedInstance)
end)

--trying out Trove

local trove = Trove.new()
local part = trove:Add(Instance.new("Part"))
warn(part.Parent)
local baseplate = trove:Add(workspace.Baseplate)
trove:Add(function()
    warn("cleaning up")
    warn(part.Parent)
end)

trove:Add(task.spawn(function()
    while task.wait(0.1) do
        print("test")
    end
end))


print(part)
task.wait(3)
trove:Clean()



