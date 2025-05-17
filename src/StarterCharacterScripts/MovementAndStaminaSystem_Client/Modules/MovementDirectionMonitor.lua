local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local zMovementDirectionEvent = Instance.new("BindableEvent")
local isMovingChangedEvent = Instance.new("BindableEvent")
export type zMovementDirection = "Forward" | "Backward" | "Stationary"
local savedZ: zMovementDirection = "Stationary"

local MovementDirectionMonitor = {
    _initialized = false
}

MovementDirectionMonitor.zMovementDirectionChanged = zMovementDirectionEvent.Event
MovementDirectionMonitor.isMovingChanged = isMovingChangedEvent.Event

function MovementDirectionMonitor.getZDirectionOfMovement(): zMovementDirection
    local DirectionOfMovement = character.HumanoidRootPart.CFrame:VectorToObjectSpace( character.HumanoidRootPart.AssemblyLinearVelocity )
    DirectionOfMovement = Vector3.new( DirectionOfMovement.X / humanoid.WalkSpeed, 0, DirectionOfMovement.Z / humanoid.WalkSpeed )
    local value = math.round(DirectionOfMovement.Z)
    local foo
    if value == 0 then
        foo = "Stationary"
    elseif value < 0 then -- Remember that in terms of the z axis, negative is forward.
        foo = "Forward"
    else
        foo = "Backward"
    end
    return foo
end

function MovementDirectionMonitor.isMovingHorizontally(): boolean
    local DirectionOfMovement = hrp.CFrame:VectorToObjectSpace( character.HumanoidRootPart.AssemblyLinearVelocity )
    DirectionOfMovement = Vector3.new( DirectionOfMovement.X / humanoid.WalkSpeed, 0, DirectionOfMovement.Z / humanoid.WalkSpeed )
    local xMagnitude = math.abs(DirectionOfMovement.X)
    local zMagnitude = math.abs(DirectionOfMovement.z)
    local threshold = 0.1
    local verdict = xMagnitude > threshold or zMagnitude > threshold
    return verdict
end

local savedIsMovingHorizontally: boolean = MovementDirectionMonitor.isMovingHorizontally()

function MovementDirectionMonitor._initialize()
    if MovementDirectionMonitor._initialized == true then
        warn("ZMovementDirectionUtility is already initialized for this character")
        return
    end
    local connections: {RBXScriptConnection} = {}
    table.insert(
        connections,
        RunService.RenderStepped:Connect(function(dt: number)
            local currentZ = MovementDirectionMonitor.getZDirectionOfMovement()
            if currentZ ~= savedZ then
                savedZ = currentZ
                zMovementDirectionEvent:Fire(currentZ)
            end

            local currentIsMovingHorizontally = MovementDirectionMonitor.isMovingHorizontally()
            if currentIsMovingHorizontally ~= savedIsMovingHorizontally then
                savedIsMovingHorizontally = currentIsMovingHorizontally
                isMovingChangedEvent:Fire(currentIsMovingHorizontally)
            end
        end)
    )
    MovementDirectionMonitor._initialized = true

    humanoid.Died:Once(function()  
        for _, connection in connections do
            if connection then
                connection:Disconnect()
                connection = nil
                MovementDirectionMonitor._initialized = false
            end
        end
    end)
end
 
MovementDirectionMonitor._initialize()

return MovementDirectionMonitor