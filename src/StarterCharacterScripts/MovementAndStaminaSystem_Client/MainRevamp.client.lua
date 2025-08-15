local player = game:GetService("Players").LocalPlayer
local playerGui = player.PlayerGui
local humanoid : Humanoid = player.Character.Humanoid or player.CharacterAdded:Wait().Humanoid

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ActionManager = require(ReplicatedStorage.RojoManaged_RS.ActionManagerSystem.ActionManager)
local MovementStateMachine = require("./Modules/MovementStateMachine")
local Config = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.Data.Config)
local StaminaManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.Stamina.StaminaManager)
local movementManagers = {
    ["Sprint"] = require("./Modules/Sprint"),
    ["Crouch"] = require("./Modules/Crouch")
}

movementManagers.Sprint.initialize()

type stuff = {
    [string]: {
        getCallbacks: ActionManager.GetCallbacks,
        keyboardAndMouseInput: Enum.KeyCode,
        gamepadInput: Enum.KeyCode,
        displayOrder: number,
        toggle: boolean?,
        progressBarCooldown: number?,
        touchButtonImageId: string
    }
}

local stuff: stuff = {
    ["Jump"] = {
        getCallbacks = function()

            local function onActivated()
                if humanoid:GetState() ~= Enum.HumanoidStateType.Freefall and humanoid:GetState() ~= Enum.HumanoidStateType.Landed then
                    StaminaManager.changeStaminaBarBy(StaminaManager.JUMP_STAMINA_COST)
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end

            local function onDeactivated()
                
            end

            StaminaManager.addBoundAction("Jump", StaminaManager.JUMP_STAMINA_COST)

            local function onUnbind()
                StaminaManager.removeBoundAction("Jump")
            end

            return onActivated, onDeactivated, onUnbind
        end,
        keyboardAndMouseInput = Enum.KeyCode.Space,
        gamepadInput = Enum.KeyCode.ButtonA,
        displayOrder = 0,
        toggle = Config.toggle["Jump"],
        progressBarCooldown = Config.cooldownTime["Jump"],
        touchButtonImageId = "rbxassetid://80131414871691"
    },
    ["Sprint"] = {
        getCallbacks = function()
            local function onActivated()
                MovementStateMachine.AddToTower("Sprint")
            end

            local function onDeactivated()
                MovementStateMachine.RemoveFromTower("Sprint")
            end

            StaminaManager.addBoundAction("Sprint", 0)

            local function onUnbind()
                StaminaManager.removeBoundAction("Sprint")
            end

            return onActivated, onDeactivated, onUnbind
        end,
        keyboardAndMouseInput = Enum.KeyCode.LeftShift,
        gamepadInput = Enum.KeyCode.ButtonL3,
        displayOrder = 2,
        toggle = Config.toggle["Sprint"],
        progressBarCooldown = Config.cooldownTime["Sprint"],
        touchButtonImageId = "rbxassetid://82611971202199"
    },
    ["Crouch"] = {
        Keycodes = {
            Enum.KeyCode.C,
            Enum.KeyCode.ButtonB
        },
        getCallbacks = function()

            local function onActivated()
                MovementStateMachine.AddToTower("Crouch")
            end

            local function onDeactivated()
                MovementStateMachine.RemoveFromTower("Crouch")
            end

            local function onUnbind()
                
            end

            return onActivated, onDeactivated, onUnbind
        end,
        keyboardAndMouseInput = Enum.KeyCode.C,
        gamepadInput = Enum.KeyCode.ButtonB,
        displayOrder = 1,
        toggle = Config.toggle["Crouch"],
        progressBarCooldown = Config.cooldownTime["Crouch"],
        touchButtonImageId = "rbxassetid://120747669726109"
    }
}

local function deactivateAllExcept(state: MovementStateMachine.CustomState?)
    for _, v in movementManagers do
        if state then
            if v ~= state then
                v.deactivate()
            end
        else
            v.deactivate()
        end
    end
end

table.insert(
    MovementStateMachine.connections,
    MovementStateMachine.currentStateChanged:Connect(function(currentState: MovementStateMachine.CustomState)  
        -- warn("currentState changed to: ", currentState, MovementStateMachine.getTower())
        if currentState == "None" then
            deactivateAllExcept(nil)
        else
            if movementManagers[currentState] then
                if not movementManagers[currentState].active then
                    deactivateAllExcept(currentState)
                    movementManagers[currentState].activate()
                end
            end
        end
    end)
)

-- Disabling default jump and binding a custom jump
local function disableDefaultJump()
    -- Disable jump bind for keyboard and mouse & gamepad users.
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)

    -- Disable default jump button for touch users.

    local function destroyJumpButtonOnAdded(touchGui: ScreenGui)
        touchGui.DescendantAdded:Connect(function(descendant: Instance) 
            if descendant.Name == "JumpButton" then
                descendant:Destroy()
            end
        end)
    end

    local function destroyJumpButton(touchGui: ScreenGui)
        local JumpButton: ImageButton? = touchGui:FindFirstChild("JumpButton") :: ImageButton?
        if JumpButton then
            JumpButton:Destroy()
        else
            destroyJumpButtonOnAdded(touchGui)
        end
    end

    local TouchGui: ScreenGui? = playerGui:FindFirstChild("TouchGui")
    if TouchGui then
        destroyJumpButton(TouchGui)
    else
        playerGui.ChildAdded:Connect(function(child)
            if child.Name == "TouchGui" and child:IsA("ScreenGui") then
                destroyJumpButton(child)
            end
        end)
    end
end
disableDefaultJump()

-- Binding custom movement
for actionName, info in stuff do
    --@warning left off here
    ActionManager.bindAction(
        actionName, 
        info.getCallbacks, 
        info.keyboardAndMouseInput, 
        info.gamepadInput, 
        info.displayOrder, 
        info.toggle, 
        info.progressBarCooldown, 
        info.touchButtonImageId
    )
    humanoid.Died:Once(function()  
        ActionManager.unbindAction(actionName)
    end)
end