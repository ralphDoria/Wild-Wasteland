local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local player = game:GetService("Players").LocalPlayer

local ScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local ViewportCharacter = require(ScriptStorage.CharacterSection.Components.ViewportCharacter)

export type ViewportController = {
    vpCharObj: ViewportCharacter.vpCharObj,
    trove: any
}

local ViewportController = {}

function ViewportController.new(viewportFrame: ViewportFrame): ViewportController
    -- make sure character is in viewport frame first
    task.wait(0.5)
    local character = player.Character or player.CharacterAdded:Wait()

    local self: ViewportController = {
        vpCharObj = ViewportCharacter.handleCharacter(viewportFrame, character),
        trove = nil
    }
    self.trove = ViewportController._connectDragToRotate(self)

    return self
end

function ViewportController.Destroy(self: ViewportController)
   self.trove:Destroy() 
   ViewportCharacter.stopHandling(self.vpCharObj)
end

function ViewportController._connectDragToRotate(self: ViewportController)
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local mouse = player:GetMouse()
    local lastX: number? = nil
    local deltaX: number = 0
    local connections = {}
    local BindName = "RestoreEquilibrium"
    local trove = Trove.new()
    
    local function cleanUpConnections()
        for _, v in connections do
            if v then
                v:Disconnect()
                v = nil
            end
        end
    end
    trove:Add(function()
        cleanUpConnections()
        RunService:UnbindFromRenderStep(BindName)
    end)

    local vpCharObj = self.vpCharObj
    trove:Add(
        vpCharObj.Viewport.InputBegan:Connect(function(io: InputObject)
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

                            cleanUpConnections()
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
    )
    return trove
end

return ViewportController