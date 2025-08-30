local Type_Item = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Shared.Type_Item)

local STATE_ORDER: {Type_Item.ItemState} = {
    [1] = "Unequipped",
    [2] = "Equipping",
    [3] = "Idle",
    [4] = "Wearing",
    [5] = "Worn"
}

local INVERSE_STATES: {[Type_Item.ItemState]: Type_Item.ItemState} = {
    ["Unequipping"] = "Equipping",
    ["Unwearing"] = "Wearing"
}

--[[
    This function gets the states that the tool has to go through to go from it's start state to the target end state.
]]
local function GetStatePath(start: Type_Item.ItemState, target: Type_Item.ItemState): {Type_Item.ItemState}
    assert(start ~= target, "Start index cannot equal target index")
    
    local function getInverseState(state: Type_Item.ItemState): Type_Item.ItemState?
        local inverseState = INVERSE_STATES[state]
        if inverseState then
            return inverseState
        else
            for k, v in INVERSE_STATES do
                if v == state then
                    return k
                end
            end
        end
        return nil
    end

    local startIndex = table.find(STATE_ORDER, start)
    if startIndex == nil then
        local inverseStartState: Type_Item.ItemState? = getInverseState(start)
        if inverseStartState then
            startIndex = table.find(STATE_ORDER, inverseStartState)
            if startIndex == nil then
                warn("start state not found in state order: " .. start)
                return {}
            end
        else
            warn("start state not found in state order: " .. start)
            return {}
        end
    end
    
    local targetIndex = table.find(STATE_ORDER, target)
    if targetIndex == nil then
        local inverseTargetState: Type_Item.ItemState? = getInverseState(target)
        if inverseTargetState then
            targetIndex = table.find(STATE_ORDER, inverseTargetState)
            if targetIndex == nil then
                warn("target state not found in state order: " .. target)
                return {}
            else
                warn("target state not found in state order: " .. target)
                return {}
            end
        end
    end

    local direction: "Forward" | "Backward" = if startIndex < targetIndex then "Forward" else "Backward"
    
    local statePath: {Type_Item.ItemState} = {}
    if direction == "Forward" then
        for i = startIndex, targetIndex, 1 do
            table.insert(statePath, STATE_ORDER[i])
        end
    else
        for i = startIndex, targetIndex, -1 do
            local originalState = STATE_ORDER[i]
            local inverseState: Type_Item.ItemState? = getInverseState(originalState)
            table.insert(statePath, inverseState or originalState)
        end
    end

    --[[
        This ensures the first state of the state path is truly the tool's starting state because the loop above may override that with
        the inverse state
    ]]
    if statePath[1] ~= start then
        table.insert(statePath, 1, start)
    end

    return statePath
end

return GetStatePath