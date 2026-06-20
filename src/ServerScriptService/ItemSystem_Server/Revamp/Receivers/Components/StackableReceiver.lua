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
local stackableBindablesFolder = ReplicatedStorage.ItemSystem_Storage.Stackable.Bindables
local stackableBindables = {
    subtractQuantityFromSum = stackableBindablesFolder.SubtractQuantityFromSum:: BindableFunction,
    getAmmoReserve = stackableBindablesFolder.GetAmmoReserve:: BindableFunction
}

-- Shared server-authority boundary (Receivers/Validation) and the extracted pure arithmetic.
local Validation = require(script.Parent.Parent.Validation)
local StackableMath = require(script.Parent.StackableMath)

-- NOTE: merge is deliberately NOT gated by caller-ownership — it legitimately operates on loot-
-- container stacks (L_INVENTORY / loot drag handlers call RequestMergeStackables). Tightening loot
-- merges to an ownership check belongs to the looting authorization layer (BUGS.md design Q5).
-- This function only hardens against type confusion + missing attributes, which it can do safely.
local function MergeQuantities(source: Tool, destination: Tool): boolean
    if not Validation.isInstance(source, "Tool") or not Validation.isInstance(destination, "Tool") then
        warn("[StackableReceiver] Rejecting merge: source/destination is not a Tool")
        return false
    end
    if source == destination then
        warn("[StackableReceiver] Rejecting merge: source equals destination")
        return false
    end
    if source.Name ~= destination.Name then
        warn("[StackableReceiver] Rejecting merge: mismatched stackable type", source.Name, destination.Name)
        return false
    end

    local maxQuantity = destination:GetAttribute("MAX_QUANTITY")
    local destinationQuantity = destination:GetAttribute("Quantity")
    local sourceQuantity = source:GetAttribute("Quantity")
    if not (Validation.isNumber(maxQuantity) and Validation.isNumber(sourceQuantity) and Validation.isNumber(destinationQuantity)) then
        warn("[StackableReceiver] Rejecting merge: missing Quantity/MAX_QUANTITY attribute")
        return false
    end

    -- keep in mind that we already check if destination is maxed on the client. Even if it was, there would effectively be no disadvantage here
    local newDestination, excessQuantity, destroySource = StackableMath.merge(sourceQuantity, destinationQuantity, maxQuantity)
    destination:SetAttribute("Quantity", newDestination)
    source:SetAttribute("Quantity", excessQuantity)
    if destroySource then
        -- source depleted; destroy the item
        source:Destroy()
    end
    return true
end

type operationsType = {
    [Player]: {
        [string | number]: Tool
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
        return MergeQuantities(source, destination)
    end

    remotes.RequestQuantityTransfer.OnServerInvoke = function(player: Player, source: Tool, destination: Tool, quantityToTransfer: number)
        if not Validation.isInstance(source, "Tool") or not Validation.isInstance(destination, "Tool") then
            return false
        end
        if source == destination or source.Name ~= destination.Name then
            return false
        end
        -- The destination is always the caller's own backpack clone produced by
        -- RequestDuplicateStackable, so an ownership check here defeats cross-player transfer abuse.
        if not Validation.ownsTool(player, destination) then
            warn("[StackableReceiver] Rejecting transfer: destination not owned by sender", player)
            return false
        end

        local sourceQuantity = source:GetAttribute("Quantity")
        local destinationQuantity = destination:GetAttribute("Quantity")
        if not (Validation.isNumber(sourceQuantity) and Validation.isNumber(destinationQuantity)) then
            return false
        end
        -- Rejects the negative-transfer DUPE (C7) while still allowing the legitimate `transfer 0`.
        if not StackableMath.canTransfer(sourceQuantity, destinationQuantity, quantityToTransfer) then
            return false
        end

        local newSource, newDestination = StackableMath.transfer(sourceQuantity, destinationQuantity, quantityToTransfer)
        source:SetAttribute("Quantity", newSource)
        destination:SetAttribute("Quantity", newDestination)
        return true
    end

    remotes.RequestDuplicateStackable.OnServerInvoke = function(player: Player, operationId: string | number, stackableToSplit: Tool)
        -- operationId is a per-client numeric counter (SplittingMenuManager), used only as a table
        -- key here — accept string or number, reject anything else (table/Instance/nil imposters).
        if typeof(operationId) ~= "string" and typeof(operationId) ~= "number" then
            return nil
        end
        if not Validation.isInstance(stackableToSplit, "Tool") then
            return nil
        end
        local stackableToSplitQuantity = stackableToSplit:GetAttribute("Quantity")
        if not Validation.isNumber(stackableToSplitQuantity) then
            return nil
        end

        -- Caller must own the stack (equipped or in their backpack), or it must be a loot-container
        -- stack. The old `FindFirstChildOfClass("Humanoid")` parent check accepted ANY player's
        -- equipped tool — i.e. you could split a stack out of another player's hands.
        local isOwned = Validation.ownsTool(player, stackableToSplit)
        local isLootStack = stackableToSplit.Parent == LootItemsHolding
        if not (isOwned or isLootStack) then
            return nil
        end

        local clone = stackableToSplit:Clone()
        -- clone:AddTag("IgnoreInventorySlotAutofill")
        clone.Parent = player.Backpack
        clone:SetAttribute("Quantity", 0)
        operations[player] = operations[player] or {} -- guard the PlayerAdded race
        operations[player][operationId] = clone
        return clone
    end

    stackableBindables.getAmmoReserve.OnInvoke = function(player: Player, stackableName: string): number
        local backpack = player.Backpack
        local character = player.Character
        local sum = 0
        if backpack then
            for _, v in backpack:GetChildren() do
                if v:IsA("Tool") and v.Name == stackableName then
                    local quantity = v:GetAttribute("Quantity")
                    if not quantity then continue end

                    sum += quantity
                end
            end
        end

        if character then
            local equippedTool = character:FindFirstChildOfClass("Tool")
            if equippedTool then
                local quantity: number? = equippedTool:GetAttribute("Quantity")
                if quantity then
                    sum += quantity
                end
            end
        end

        return sum
    end

    stackableBindables.subtractQuantityFromSum.OnInvoke = function(player: Player, stackableName: string, quantityToSubtract: number): boolean
        assert(typeof(stackableName) == "string" and typeof(quantityToSubtract) == "number")

        local backpack = player.Backpack
        local character = player.Character

       local validStackables = {} 
        
        local sum = 0
        if backpack then
            for _, v in backpack:GetChildren() do
                if v:IsA("Tool") and v.Name == stackableName then
                    local quantity = v:GetAttribute("Quantity")
                    if not quantity then continue end

                    sum += quantity
                    table.insert(validStackables, {v, quantity})
                end
            end
        end

        if character then
            local equippedTool = character:FindFirstChildOfClass("Tool")
            if equippedTool then
                local quantity: number? = equippedTool:GetAttribute("Quantity")
                if quantity then
                    sum += quantity
                    table.insert(validStackables, {equippedTool, quantity})
                end
            end
        end

        if quantityToSubtract <= sum then
            for _, v in validStackables do
                local stackable = v[1]
                local quantity = v[2]
                local result = quantity - quantityToSubtract
                if result > 0 then
                    stackable:SetAttribute("Quantity", result)
                    return true
                elseif result == 0 then
                    stackable:SetAttribute("Quantity", result)
                    stackable:Destroy()
                    return true
                elseif result < 0 then
                    stackable:SetAttribute("Quantity", 0)
                    stackable:Destroy()
                    quantityToSubtract = -1 * result
                    continue
                end
            end
            return false
        else
            return false
        end
    end

    remotes.CancelDuplicateRequest.OnServerEvent:Connect(function(player: Player, operationId: string | number)
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
        if not Validation.isInstance(tool, "Tool") then
            return
        end
        local isStackable = tool:GetAttribute("Quantity") ~= nil
        -- unused split-slot stackables should only be in the player's backpack if truly unused
        local doesBelongToPlayer = tool.Parent == player.Backpack
        if not (isStackable and doesBelongToPlayer) then
            warn("[StackableReceiver] Rejecting DestroyUnusedStackable: not a stackable the sender owns", player)
            return
        end

        tool:Destroy()
    end)
end
