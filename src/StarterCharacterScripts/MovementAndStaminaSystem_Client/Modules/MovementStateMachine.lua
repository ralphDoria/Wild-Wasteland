local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

export type CustomState = "Sprint" | "Crouch" | "None"

local MovementStateMachine = {}

MovementStateMachine.CurrentState = "None" :: CustomState
MovementStateMachine.tower = {}
MovementStateMachine.TargetState = "None" :: CustomState
MovementStateMachine.towerUpdatedEvent = Instance.new("BindableEvent").Event

function MovementStateMachine.SetState(state : CustomState)
    MovementStateMachine.CurrentState = state
    character:SetAttribute("State", state)
end

function MovementStateMachine.RemoveFromTower(state: CustomState)
    local index = table.find(MovementStateMachine.tower, state)
    if index then
        table.remove(MovementStateMachine.tower, index)
    end
    MovementStateMachine.TargetState = MovementStateMachine.getTopOfTower()
end

function MovementStateMachine.AddToTower(state : CustomState)
    MovementStateMachine.RemoveFromTower(state) --if state is already in tower, then remove it and add it to the top (may be redundant if state is already at the top)
    table.insert(MovementStateMachine.tower, state)
    MovementStateMachine.TargetState = MovementStateMachine.getTopOfTower()
end

function MovementStateMachine.towerIsEmpty()
    return #MovementStateMachine.tower == 0
end

function MovementStateMachine.getTopOfTower()
    return if MovementStateMachine.towerIsEmpty() then "None" else MovementStateMachine.tower[#MovementStateMachine.tower]
end

function MovementStateMachine.GetState()
    return MovementStateMachine.CurrentState
end

return MovementStateMachine