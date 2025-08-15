local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

export type CustomState = "Sprint" | "Crouch" | "None"

local MovementStateMachine = {
    _initialized = false,
    connections = {}
}

local currentState: CustomState = "None"
local tower: {CustomState} = {}
local currentStateChangedEvent: BindableEvent = Instance.new("BindableEvent")
MovementStateMachine.currentStateChanged = currentStateChangedEvent.Event

function MovementStateMachine.SetState(state : CustomState)
    currentState = state
    character:SetAttribute("State", state)
end

function MovementStateMachine.RemoveFromTower(state: CustomState)
    local index = table.find(tower, state)
    if index then
        table.remove(tower, index)
        if currentState ~= MovementStateMachine.getTopOfTower() then
            currentState = MovementStateMachine.getTopOfTower()
            currentStateChangedEvent:Fire(currentState)
        end
    end
end

function MovementStateMachine.AddToTower(state : CustomState)
    -- If state is already in tower and isn't at the top, then remove it and add it to the top.
    local index = table.find(tower, state)
    if index and index ~= #tower then
        table.remove(tower, index)
        table.insert(tower, state)
        currentState = MovementStateMachine.getTopOfTower()
        currentStateChangedEvent:Fire(currentState)
    elseif index == #tower then
        return
    else
        table.insert(tower, state)
        currentState = MovementStateMachine.getTopOfTower()
        currentStateChangedEvent:Fire(currentState)
    end
end

function MovementStateMachine.towerIsEmpty()
    return #tower == 0
end

function MovementStateMachine.getTopOfTower()
    return if MovementStateMachine.towerIsEmpty() then "None" else tower[#tower]
end

function MovementStateMachine.GetState()
    return currentState
end

function MovementStateMachine.getTower()
    return tower
end

function MovementStateMachine._initialize()
    MovementStateMachine._initialized = true
end

MovementStateMachine._initialize()

return MovementStateMachine