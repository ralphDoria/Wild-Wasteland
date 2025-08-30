local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage.ItemSystem_Storage

local remotes = {
    RequestMergeStackables = ItemSystem_Storage.Stackable.Remotes.RequestMergeStackables:: RemoteFunction,
}

local function MergeQuantities(source: Tool, destination: Tool)
    assert(source.Name == destination.Name, "Error: not the same stackable type")
    assert(source ~= destination, "Source stackable cannot equal destination stackable.")
    assert(source and destination, "Source and Destination have to be non nil values")
    local MAX_QUANTITY = destination:GetAttribute("MAX_QUANTITY"):: number

    -- keep in mind that we already check if destination is maxed on the client. Even if it was, there would effectively be no disadvantage here
    print("starting merge")
    local destinationQuantity = destination:GetAttribute("Quantity"):: number
    local sourceQuantity = source:GetAttribute("Quantity"):: number
    local result = sourceQuantity + destinationQuantity

    print(sourceQuantity, destinationQuantity)
    print(result)
    destination:SetAttribute("Quantity", math.min(result, MAX_QUANTITY))
    local excessQuantity: number = result - MAX_QUANTITY

    if excessQuantity > 0 then
        source:SetAttribute("Quantity", excessQuantity)
    else

        -- source depleted; destroy the item
        -- handle this your own way, i'll just unassign its type
        -- destroy source
        source:Destroy()
    end
end

return function()
    remotes.RequestMergeStackables.OnServerInvoke = function(player: Player, source: Tool, destination: Tool)
        MergeQuantities(source, destination)
        return
    end
end
