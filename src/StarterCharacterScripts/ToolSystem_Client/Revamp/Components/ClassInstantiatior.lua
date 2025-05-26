local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local humanoid = player.Character:FindFirstChildOfClass("Humanoid", true) or player.CharacterAdded:Wait():FindFirstChildOfClass("Humanoid", true)
local toolTags = {
     ["Melee"] = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.Subclasses.Melee),--the tool tag is just going to be the name of the tool
     ["HealingInjection"] = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.Items.Consumables.HealingInjection)
}

return function()
    local function handleTaggedInstances(instance, class)
        if not instance:IsA("Tool") then
            warn("tagged instance is not a tool")
        end
        warn("creating new Instance of", instance.Name, "in", instance.Parent)
        task.spawn(function()
            class.new(instance, humanoid)
        end)
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