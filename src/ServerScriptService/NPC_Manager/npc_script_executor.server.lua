local tag = "npc_mutantRoach"
local targetPart = game.Workspace:FindFirstChild("npc_roach_test"):FindFirstChild("targetLocation")
local CollectionService = game:GetService("CollectionService")
local mutantRoach = require("./mutantRoach")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require("../../../../ReplicatedStorage/Packages/Trove") :: any

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
local baseplate = trove:Add(workspace:FindFirstChild("Baseplate"))
trove:Add(function()
    warn("cleaning up")
    warn(part.Parent)
end)

--trove:Clean()