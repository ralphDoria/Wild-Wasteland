local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local humanoid = player.Character:FindFirstChildOfClass("Humanoid", true) or player.CharacterAdded:Wait():FindFirstChildOfClass("Humanoid", true)
local toolTags = {
     ["Barbed Bat"] = require(RS:FindFirstChild("BarbedBat", true)),--the tool tag is just going to be the name of the tool
}

return function()
    local function handleTaggedInstances(instance, class)
        if not instance:IsA("Tool") then
            warn("tagged instance is not a tool")
        end
        warn("creating new Instance of " .. instance.Name)
        class.new(instance, humanoid)
    end
    
    for tag, class in toolTags do
        for _, taggedInstance in CollectionService:GetTagged(tag) do
            if not taggedInstance:HasTag("vmTool") then
                handleTaggedInstances(taggedInstance, class)
            end
        end
        CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance)
            if not taggedInstance:HasTag("vmTool") then
                handleTaggedInstances(taggedInstance, class)
            end
        end)
    end
end