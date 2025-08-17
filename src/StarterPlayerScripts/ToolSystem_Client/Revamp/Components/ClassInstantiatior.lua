local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local humanoid = player.Character:FindFirstChildOfClass("Humanoid", true) or player.CharacterAdded:Wait():FindFirstChildOfClass("Humanoid", true)
local toolTags = {
     ["Melee"] = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.Subclasses.Melee),--the tool tag is just going to be the name of the tool
     ["HealingInjection"] = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.Items.Consumables.HealingInjection),
     ["NV Goggles"] = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.Items.Wearables.NVGoggles),
     ["StorageWearable"] = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.Subclasses.StorageWearable)
}
local Promise = require(ReplicatedStorage.Packages.Promise)

return function()
    local function handleTaggedInstances(instance, class)
        if not instance:IsA("Tool") then
            warn("tagged instance is not a tool")
        end
        -- warn("creating new Instance of", instance.Name, "in", instance.Parent)
        Promise.new(function(resolve, reject)
            class.new(instance, humanoid)
            
            -- only instantiate when item is in player's inventory (check w/ backpack.ChildAdded) and destroy when player drops item. This prevents client for being burdened w/ item data that it doesn't need at the moment (e.g. a gun that is dropped on the opposite side of the map
            -- but still rendered)

            -- use .updateCharacter() function when character dies)
        end)
            :andThen(function()
                -- warn("Successfully created a new Instance of", instance.Name, "in", instance.Parent)
            end)
            :catch(function(err)
                warn("Something went wrong when attempting to create a new instance of", instance.Name, "in", instance.Parent)
                warn(err)
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
                print("handling tagged instance")
                handleTaggedInstances(taggedInstance, class)
            end
        end)
    end
end