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

local function instantiateTool(tool: Tool): (any?, ((any) -> ())?)
    for tag, class in toolTags do
        if tool:HasTag(tag) then

            local itemInstance
            local destroyFunction

            Promise.new(function(resolve, reject)
                itemInstance = class.new(tool, humanoid)
                if itemInstance then
                    destroyFunction = class.Destroy
                    resolve()
                else
                    reject()
                end
            end)
                :andThen(function(itemInstance)
                    -- warn(`instantiateTool promise has resolved for {tool}`)
                end)
                :catch(function(err)
                    warn("Something went wrong when attempting to create a new instance of", tool.Name, "in", tool.Parent)
                    warn(err)
                end)
                :await()
            
            return itemInstance, destroyFunction
        end
    end

    return nil
end

return instantiateTool