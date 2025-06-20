local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local ViewportCharacter = require(ScriptStorage.CharacterSection.Components.ViewportCharacter)

local ViewportController = {}

function ViewportController.init()
    -- make sure character is in viewport frame first
    task.wait(0.5)
    local character = References_Inventory.player.Character or References_Inventory.player.CharacterAdded:Wait()
    local vpCharObj = ViewportCharacter.handleCharacter(References_Inventory.Viewport, character)
    local connection = ViewportController._connectDragToRotate(vpCharObj)
    local humanoid = character:WaitForChild("Humanoid"):: Humanoid
    humanoid.Died:Once(function()  
        connection:Disconnect()
    end)
end

function ViewportController._connectDragToRotate(vpCharObj: ViewportCharacter.vpCharObj): RBXScriptConnection
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local mouse = References_Inventory.player:GetMouse()
    local lastX: number? = nil
    local deltaX: number = 0
    local connections = {}
    local BindName = "RestoreEquilibrium"

    return References_Inventory.Viewport.InputBegan:Connect(function(io: InputObject)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            
            RunService:UnbindFromRenderStep(BindName)
            lastX = mouse.X

            table.insert(
                connections,
                UIS.InputChanged:Connect(function(io: InputObject)
                    if io.UserInputType == Enum.UserInputType.MouseMovement then

                        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                            local currentX = mouse.X
                            deltaX = lastX - currentX
                            vpCharObj.CameraPosition = CFrame.Angles(vpCharObj.CameraPosition:ToOrientation())*CFrame.Angles(0, (2*math.pi)*(1/200)*deltaX, 0) * vpCharObj.CameraRadius
                            print("Dragging")
                            lastX = currentX
                        end

                    end
                end)
            )

            table.insert(
                connections,
                UIS.InputEnded:Connect(function(io: InputObject, a1: boolean)  
                    if io.UserInputType == Enum.UserInputType.MouseButton1 then

                        for _, v in connections do
                            v:Disconnect()
                        end
                        local accumulatedTime = 0
                        local lastCameraPosition = vpCharObj.CameraPosition
                        local _, y, _ = lastCameraPosition:ToOrientation()
                        local SECONDS_TO_ROTATE_180 = 2
                        local secondsUntilHomeostasis = SECONDS_TO_ROTATE_180 * (math.abs(y) / (math.pi))
                        print(math.abs(y), secondsUntilHomeostasis)
                        RunService:BindToRenderStep(BindName, 201, function(delta: number) 
                            print("running")
                            accumulatedTime += delta
                            local alpha = accumulatedTime/secondsUntilHomeostasis
                            vpCharObj.CameraPosition =
                                CFrame.Angles(lastCameraPosition:ToOrientation()):Lerp(CFrame.Angles(vpCharObj.CameraRadius:ToOrientation()), alpha)
                                    * vpCharObj.CameraRadius
                            if alpha >= 1 then
                                RunService:UnbindFromRenderStep(BindName)
                            end
                        end)

                    end
                end)
            )
        end
    end)
end

return ViewportController