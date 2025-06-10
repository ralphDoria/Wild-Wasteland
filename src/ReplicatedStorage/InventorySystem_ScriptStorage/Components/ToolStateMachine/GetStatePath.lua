local ItemState = require("./ItemState")

local STATE_ORDER: {ItemState.ItemState} = {
    [1] = "Unequipped",
    [2] = "Equipping",
    [3] = "Idle",
    [4] = "Wearing",
    [5] = "Worn"
}

local INVERSE_STATES: {[ItemState.ItemState]: ItemState.ItemState} = {
    ["Unequipping"] = "Equipping",
    ["Unwearing"] = "Wearing"
}

--[[
    This function gets the states that the tool has to go through to go from it's start state to the target end state.
]]
local function GetStatePath(start: ItemState.ItemState, target: ItemState.ItemState): {ItemState.ItemState}
    assert(start ~= target, "Start index cannot equal target index")
    
    local function getInverseState(state: ItemState.ItemState): ItemState.ItemState?
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
        local inverseStartState: ItemState.ItemState? = getInverseState(start)
        if inverseStartState then
            startIndex = table.find(STATE_ORDER, inverseStartState)
            if startIndex == nil then
                warn("target state not found in state order: " .. start)
                return {}
            end
        else
            warn("target state not found in state order: " .. target)
            return {}
        end
    end
    
    local targetIndex = table.find(STATE_ORDER, target)
    if targetIndex == nil then
        local inverseTargetState: ItemState.ItemState? = getInverseState(target)
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
    
    local statePath: {ItemState.ItemState} = {}
    if direction == "Forward" then
        for i = startIndex, targetIndex, 1 do
            table.insert(statePath, STATE_ORDER[i])
        end
    else
        for i = startIndex, targetIndex, -1 do
            local originalState = STATE_ORDER[i]
            local inverseState: ItemState.ItemState? = getInverseState(originalState)
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