local tag = "npc_mutantRoach"
local targetPart = game.Workspace.npc_roach_test.targetLocation
local CollectionService = game:GetService("CollectionService")
local mutantRoach = require(script.Parent.mutantRoach)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local trove = require(ReplicatedStorage.Packages.Trove)

local function mutantRoachTagHandler(taggedInstance)
    local roach = mutantRoach.new(taggedInstance)
    roach:turnOn()
end

--<<EXECUTING CODE BELOW>>
for _, taggedInstance in CollectionService:GetTagged(tag) do
    mutantRoachTagHandler(taggedInstance)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
    mutantRoachTagHandler(taggedInstance)
end)