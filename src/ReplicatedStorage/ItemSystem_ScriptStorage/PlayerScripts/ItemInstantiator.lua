local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

local Classes = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes
local toolTags = {
    ["Melee"] = require(Classes.Subclasses.Melee),--the tool tag is just going to be the name of the tool
    ["HealingInjection"] = require(Classes.Items.Consumables.HealingInjection),
    ["NV Goggles"] = require(Classes.Items.Wearables.NVGoggles),
    ["StorageWearable"] = require(Classes.Subclasses.StorageWearable),
    ["Stackable"] = require(Classes.Subclasses.Stackable),
    ["Gun"] = require(Classes.Subclasses.Gun)
}
local Promise = require(ReplicatedStorage.Packages.Promise)
local handleTaggedInstance = require(ReplicatedStorage.RojoManaged_RS.Utility.handleTaggedInstances)

local ItemInstantiator = {}

export type DestroyInfo = {
    itemInstance: any,
    destroyFunction: (any) -> ()
}
ItemInstantiator.toolToDestroyInfoMap = {}:: {[Tool]: DestroyInfo}
ItemInstantiator.toolPromptObjects = {}


function ItemInstantiator.initToolPrompts()
    for tag, _ in toolTags do
        handleTaggedInstance(
            tag, 
            function(taggedInstance: Instance) -- onTagged 
                if taggedInstance:HasTag("vmTool") then
                    -- warn("Not creating tool prompt for this tagged instance because it is a viewmmodel tool")
                    return
                end

                --give item a default state
                taggedInstance:SetAttribute("State", "Unequipped")
                task.spawn(function()
                    ItemInstantiator.toolPromptObjects[taggedInstance] = References_ItemSystem.ToolPromptManager.new(taggedInstance:: Tool)
                end)
            end, 
            function(taggedInstance: Instance) -- onUntagged
                if taggedInstance:HasTag("vmTool") then
                    return
                end
                --[[
                This will probably error because onUntagged will run when the instance is being destroyed, & thus taggedInstance won't exist in toolPromptObjects. I can't
                think of a solution right now, however
                ]]
                -- warn(`DESTROYING TOOL PROMPT`)
                References_ItemSystem.ToolPromptManager.Destroy(ItemInstantiator.toolPromptObjects[taggedInstance])
            end
        )
    end
end

function ItemInstantiator.initClientReceivers()

end

function ItemInstantiator.instantiateTool(tool: Tool): (any?, ((any) -> ())?)
    for tag, class in toolTags do
        if tool:HasTag(tag) then

            local itemInstance
            local destroyFunction

            Promise.new(function(resolve, reject)
                itemInstance = class.new(tool)
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

return ItemInstantiator