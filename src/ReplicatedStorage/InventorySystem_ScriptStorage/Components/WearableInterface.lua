--!strict

local player = game:GetService("Players").LocalPlayer
local playerGui : PlayerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame
local WearableSection : Frame = MainInventory:FindFirstChild("WearableSection") :: Frame
local WearableSlotsContainer: Frame = WearableSection:FindFirstChild("WearableSlotsContainer", true) :: Frame
local Templates = WearableSection:FindFirstChild("Templates") :: Folder
local circle = Templates:FindFirstChild("Circle"):: ImageLabel
local line = Templates:FindFirstChild("Line"):: ImageLabel
local Slot = require("./Slot/Slot")
local ViewportCharacter = require("./ViewportCharacter")
local ViewportFrame = WearableSection:FindFirstChildWhichIsA("ViewportFrame", true) :: ViewportFrame
local RunService = game:GetService("RunService")
local PointDimensionalConverter = require("./PointDimensionalConverter")
local mouse = player:GetMouse()
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local WearableSlotInfo = require("./WearableSlotInfo")
local WearableCategory = require("./WearableCategory")
local FilledSlotsTracker = require("./Slot/FilledSlotsTracker")

local WearableInterface = {}

function WearableInterface.initialize(character: Model)
    -- make sure character is in viewport frame first
    task.wait(0.5)
    local vpCharObj = ViewportCharacter.handleCharacter(ViewportFrame, character)

    local wearableGuiInstances = Instance.new("Folder")
    wearableGuiInstances.Parent = gui

    for key, v in WearableSlotInfo do
        WearableCategory.typeCheck(key)
        v.slot = Slot.new("Wearable", key:: WearableCategory.WearableCategoryType)
        FilledSlotsTracker.WearableSlots[key] = v.slot
        v.slot._itself.AnchorPoint = Vector2.new(0.5, 0.5)
        v.slot._itself.ZIndex = 2
        v.slot._itself.LayoutOrder = v.LayoutOrder
        v.slot.ImageButton.Image = v.image
        v.slot.ImageButton.Rotation = 0
        v.slot.ImageButton.Visible = true
        v.slot._itself.Name = key
        v.slot._itself.Parent = WearableSlotsContainer
        v.circle = circle:Clone()
        v.circle.Visible = true
        v.circle.Parent = wearableGuiInstances
        v.line = line:Clone()
        v.line.Visible = true
        v.line.Parent = wearableGuiInstances
    end

    MainInventory:GetPropertyChangedSignal("Visible"):Connect(function(...: any)  
        for _, v in wearableGuiInstances:GetChildren() do
            if v:IsA("GuiObject") then
                v.Visible = MainInventory.Visible
            end
        end
    end)

    local UIS = game:GetService("UserInputService")
    local lastX: number? = nil
    local deltaX: number = 0
    local connections = {}
    local BindName = "RestoreEquilibrium"

    ViewportFrame.InputBegan:Connect(function(io: InputObject)
        if io.UserInputType == Enum.UserInputType.MouseButton1 then
            
            RunService:UnbindFromRenderStep(BindName)
            lastX = mouse.X

            table.insert(
                connections,
                UserInputService.InputChanged:Connect(function(io: InputObject)
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
                UserInputService.InputEnded:Connect(function(io: InputObject, a1: boolean)  
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
    

    -- based off character's torso CFrame and offsets from that, 
    RunService.RenderStepped:Connect(function(dt: number)  
        local torso: BasePart = vpCharObj.Viewmodel:FindFirstChild("Torso") :: BasePart
        if torso then
            for k, v in WearableSlotInfo do
                local screenPosition : UDim2 = PointDimensionalConverter.get2DPosition((torso.CFrame * v.torsoOffset).Position, vpCharObj.Camera, ViewportFrame)

                --positioning the circle
                local circlePosition : UDim2 = screenPosition
                v.circle.Position = circlePosition

                -- --positioning the slot
                -- v.slot._itself.AnchorPoint = Vector2.new(0.5, 0.5)
                -- v.slot._itself.Position = circlePosition  + UDim2.fromOffset(v.slot._itself.AbsoluteSize.Y * v.uiOffsetMultiplier, 0)
                

                --connecting a line between the circle and slot
                local guiInset: UDim2 = UDim2.fromOffset(GuiService:GetGuiInset().X, GuiService:GetGuiInset().Y)
                local manualAnchorPointAddition = UDim2.fromOffset(v.slot._itself.AbsoluteSize.X/2, v.slot._itself.AbsoluteSize.X/2)
                local slotAbsolutePosition = UDim2.fromOffset(v.slot._itself.AbsolutePosition.X, v.slot._itself.AbsolutePosition.Y) 
                    + manualAnchorPointAddition + guiInset
                local hypotenuse, theta = PointDimensionalConverter.findHypotenuseAndTheta(slotAbsolutePosition, circlePosition)
                v.line.Size = UDim2.fromOffset(2, hypotenuse)
                v.line.Position = circlePosition:Lerp(slotAbsolutePosition, 0.5)
                v.line.Rotation = math.deg(theta) + 90
            end 
        end
    end)
end

return WearableInterface