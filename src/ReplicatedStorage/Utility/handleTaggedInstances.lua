local CollectionService = game:GetService("CollectionService")

local function handleTaggedInstances<k>(tag: string, whenTagged: (taggedInstance: k) -> (), whenUntagged: (taggedInstance: k) -> ()): {RBXScriptConnection}
    for _, taggedInstance in CollectionService:GetTagged(tag) do
        whenTagged(taggedInstance)
    end

    local connections = {}

    table.insert(
        connections,
        CollectionService:GetInstanceAddedSignal(tag):Connect(function(taggedInstance: k)  
            whenTagged(taggedInstance)
        end)
    )

    table.insert(
        connections,
        CollectionService:GetInstanceRemovedSignal(tag):Connect(function(taggedInstance: k)  
            whenUntagged(taggedInstance)
        end)
    )

    return connections
end

return handleTaggedInstances