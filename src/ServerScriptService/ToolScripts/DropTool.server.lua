------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local COLLECTION_TAG = "Droppable"

------------------------------------------------------------------------<<<ROBLOX LIBRARIES & SERVICES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

------------------------------------------------------------------------<<<Modules (Classes, Data Package, Utility, Functional)>>>
local detectDroppedToolHitFloor = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("DetectDroppedToolHitFloor"))

------------------------------------------------------------------------<<<FUNCTIONS>>>
local function handleTaggedInstance(taggedObject)
    local tool = taggedObject
    --<<<REMOTE & BINDABLE EVENTS>>>--
    local Events = tool:WaitForChild("Events")
    local RemoteEvents = Events:WaitForChild("RemoteEvents")
    local rev_dropped : RemoteEvent = RemoteEvents:WaitForChild("Dropped")

    rev_dropped.OnServerEvent:Connect(function(player)
        tool.Parent = game.Workspace
        detectDroppedToolHitFloor(tool)
    end)
end

------------------------------------------------------------------------<<<EVENT CONNECTIONS>>>
for _, v in CollectionService:GetTagged(COLLECTION_TAG) do
    handleTaggedInstance(v)
end
CollectionService:GetInstanceAddedSignal(COLLECTION_TAG):Connect(function(object)
    handleTaggedInstance(object)
end)