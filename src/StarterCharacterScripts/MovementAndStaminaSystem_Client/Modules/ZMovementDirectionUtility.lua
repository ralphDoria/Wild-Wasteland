local RunService = game:GetService("RunService")
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local zMovementDirectionEvent = Instance.new("BindableEvent")
export type zMovementDirection = "Forward" | "Backward" | "Stationary"
local saved: zMovementDirection = "Stationary"

local ZMovementDirectionUtility = {
    _initialized = false
}

ZMovementDirectionUtility.zMovementDirectionChanged = zMovementDirectionEvent.Event

function ZMovementDirectionUtility.getZDirectionOfMovement(): zMovementDirection
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

function ZMovementDirectionUtility._initialize()
    if ZMovementDirectionUtility._initialized == true then
        warn("ZMovementDirectionUtility is already initialized for this character")
        return
    end
    local connection
    connection = RunService.RenderStepped:Connect(function(dt: number)
        local current = ZMovementDirectionUtility.getZDirectionOfMovement()
        if current ~= saved then
            saved = current
            zMovementDirectionEvent:Fire(current)
        end
    end)
    ZMovementDirectionUtility._initialized = true

    humanoid.Died:Once(function()  
        if connection then
            connection:Disconnect()
            connection = nil
            ZMovementDirectionUtility._initialized = false
        end
    end)
end

ZMovementDirectionUtility._initialize()

return ZMovementDirectionUtility