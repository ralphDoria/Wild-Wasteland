local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage.ItemSystem_Storage
local LootItemsHolding = ReplicatedStorage.LootingSystem_Storage.LootItemsHolding:: Folder

local stackableRemotes = ItemSystem_Storage.Stackable.Remotes:: Folder
local remotes = {
    RequestMergeStackables = stackableRemotes.RequestMergeStackables:: RemoteFunction,
    RequestDuplicateStackable = stackableRemotes.RequestDuplicateStackable:: RemoteFunction,
    RequestQuantityTransfer = stackableRemotes.RequestQuantityTransfer:: RemoteFunction,
    DestroyUnusedStackable = stackableRemotes.DestroyUnusedStackable:: RemoteEvent,
    CancelDuplicateRequest = stackableRemotes.CancelDuplicateRequest:: RemoteEvent,
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

type operationsType = {
    [Player]: {
        [string]: Tool
    }
}

local operations: operationsType = {}


return function()

    Players.PlayerAdded:Connect(function(player: Player)  
        operations[player] = {}
    end)

    Players.PlayerRemoving:Connect(function(player: Player)  
        operations[player] = nil
    end)

    remotes.RequestMergeStackables.OnServerInvoke = function(player: Player, source: Tool, destination: Tool)
        MergeQuantities(source, destination)
        return
    end

    remotes.RequestQuantityTransfer.OnServerInvoke = function(player: Player, source: Tool, destination: Tool, quantityToTransfer: number) 
        local currentSourceQuantity = source:GetAttribute("Quantity")
        local destinationQuantity = destination:GetAttribute("Quantity")
        local originalSourceQuantity = currentSourceQuantity + destinationQuantity
        assert(currentSourceQuantity and destinationQuantity and quantityToTransfer < originalSourceQuantity)
        assert(source.Name == destination.Name, "Error: not the same stackable type")
        source:SetAttribute("Quantity", originalSourceQuantity - quantityToTransfer)
        destination:SetAttribute("Quantity", quantityToTransfer)
        return true
    end

    remotes.RequestDuplicateStackable.OnServerInvoke = function(player: Player, operationId: string, stackableToSplit: Tool)
        local stackableToSplitQuantity = stackableToSplit:GetAttribute("Quantity")
        assert(stackableToSplitQuantity and operationId)
        local parent = stackableToSplit.Parent
        local hasValidParent = parent and (parent:FindFirstChildOfClass("Humanoid") or parent:IsA("Backpack") or parent == LootItemsHolding)
        if hasValidParent  then
            local clone = stackableToSplit:Clone()
            clone:AddTag("IgnoreInventorySlotAutofill")
            clone.Parent = player.Backpack
            clone:SetAttribute("Quantity", 0)
            operations[player][operationId] = clone
            return clone
        else
            return nil
        end
    end



    remotes.CancelDuplicateRequest.OnServerEvent:Connect(function(player: Player, operationId: string)
        local playerOperations = operations[player]
        if playerOperations then
            local operationResult: Tool? = playerOperations[operationId]
            if operationResult then
                operationResult:Destroy()
                playerOperations[operationId] = nil
            end
        end
    end)

    remotes.DestroyUnusedStackable.OnServerEvent:Connect(function(player: Player, tool: Tool)  
        assert(tool, "Tool doesn't exist")
        local isStackable = tool:GetAttribute("Quantity")
        local doesBelongToPlayer = tool.Parent == player.Backpack -- unused split split slot stackables should only be in the player's backpack if truly unused

        assert(isStackable and doesBelongToPlayer, "Tool is either not a stackable or doesn't belong to the requesting client")

        tool:Destroy()
        print("Destroyed unused stackable")
    end)
end
