local player = game:GetService("Players").LocalPlayer
local humanoid : Humanoid = player.Character.Humanoid or player.CharacterAdded:Wait().Humanoid

local ContextActionService = game:GetService("ContextActionService")
local MovementStateMachine = require("./Modules/MovementStateMachine")
local config = {
    speed = {
        sprint = 20,
        crouch = 3
    }
}

local toggle = false

local stuff = {
    ["Sprint"] = {
        Keycodes = {
            Enum.KeyCode.LeftShift,
            Enum.KeyCode.ButtonL3
        },
        speed = 16,
        functionToBind = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject) : Enum.ContextActionResult
            if toggle then
                if inputState == Enum.UserInputState.Begin then
                
                end
            end
            MovementStateMachine.AddToTower("Sprint")
            return Enum.ContextActionResult.Pass
        end
    },
    ["Crouch"] = {
        Keycodes = {
            Enum.KeyCode.C,
            Enum.KeyCode.ButtonB
        },
        speed = 3,
        functionToBind = function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject) : Enum.ContextActionResult
            MovementStateMachine.AddToTower("Crouch")
            return Enum.ContextActionResult.Pass
        end
    }
}

for actionName, info in stuff do
    ContextActionService:BindAction(actionName, info.functionToBind, true, info.Keycodes)
end

humanoid.Running:Connect(function()
    if MovementStateMachine.TargetState == "Sprint" then
        MovementStateMachine.SetState("Sprint")
    end
end)
