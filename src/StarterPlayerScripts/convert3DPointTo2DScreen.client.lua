local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local bindName = "wearableUISlots"
local player = game:GetService("Players").LocalPlayer
local Workspace = game:GetService("Workspace")
local screenGui : ScreenGui = player.PlayerGui:WaitForChild("3Dto2D")
local viewportFrame = screenGui:FindFirstChildWhichIsA("ViewportFrame", true)
--local wearableAreas = screenGui:FindFirstChild("wearableAreas", true) or workspace:FindFirstChild("wearableAreas", true)
local character = player.Character or player.CharacterAdded:Wait()
local circleTemplate = screenGui:FindFirstChild("Circle")
local slotTemplate = screenGui:FindFirstChild("Square")
local lineTemplate = screenGui:FindFirstChild("Line")

character.Archivable = true
local clonedCharacter : Model = character:Clone()
clonedCharacter:FindFirstChild("RojoManaged_SCS"):Destroy()
clonedCharacter:PivotTo(CFrame.new(0, 1.5, 0))
clonedCharacter.Parent = viewportFrame:FindFirstChildOfClass("WorldModel")

local vpCameraRadius : number = 7

local vpCamera = Instance.new("Camera")
vpCamera.Parent = viewportFrame
viewportFrame.CurrentCamera = vpCamera
vpCamera.CFrame = CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, vpCameraRadius)

local infoTable = {
    Head = {
        threeD = clonedCharacter:FindFirstChild("Torso").CFrame * CFrame.new(0, 1.5, 0),
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = 1
        },
        initialSlotPosition = nil
    },
    Torso = {
        threeD = clonedCharacter:FindFirstChild("Torso").CFrame,
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = -1
        },
        initialSlotPosition = nil
    },
    Legs = {
        threeD = clonedCharacter:FindFirstChild("Torso").CFrame * CFrame.new(0, -1.5, 0),
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = 1
        },
        initialSlotPosition = nil
    },
    Feet = {
        threeD = clonedCharacter:FindFirstChild("Torso").CFrame * CFrame.new(0, -2.5, 0),
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = -1
        },
        initialSlotPosition = nil
    }
}

for _, area in infoTable do
    for _, uiElement in area.twoD do
        if type(uiElement) ~= "number" then
            uiElement.Parent = screenGui
        end
    end
end

local function get2DPosition(Position: Vector3, camera : Camera) : UDim2
	local ScreenPosition : Vector3, inView : boolean = camera:WorldToViewportPoint(Position)
	local ScreenSize : Vector2 = camera.ViewportSize

	if inView then
        if camera == workspace.CurrentCamera then
            local Vector2Position = Vector2.new(math.clamp(ScreenPosition.X, 0, ScreenSize.X), math.clamp(ScreenPosition.Y, 0, ScreenSize.Y))
            return UDim2.fromOffset(Vector2Position.X, Vector2Position.Y)
        else
            local vpFrame = camera.Parent --if it's not the workspace's CurrentCamera, then the Camera should be parented to a ViewportFrame
            local xOffset = vpFrame.AbsolutePosition.X + ScreenPosition.X * vpFrame.AbsoluteSize.X
            local yOffset = vpFrame.AbsolutePosition.Y + ScreenPosition.Y * vpFrame.AbsoluteSize.Y
            local pos = UDim2.fromOffset(xOffset, yOffset)
            if screenGui.IgnoreGuiInset == true then
                --need to manually take into account gui inset
                pos = pos + UDim2.fromOffset(GuiService:GetGuiInset().X, GuiService:GetGuiInset().Y)
            end
            return pos
        end
	else
		local Vector2Position = Vector2.new(math.clamp(ScreenPosition.X, 0, ScreenSize.X), math.clamp(ScreenPosition.Y, 0, ScreenSize.Y))
		local scaleX = Vector2Position.X / ScreenSize.X
		local scaleY = Vector2Position.Y / ScreenSize.Y
		return UDim2.fromOffset(scaleX, scaleY)
	end
end

local function findHypotenuseAndTheta(point1: UDim2, point2 : UDim2) : number
    local x = point1.X.Offset - point2.X.Offset
    local y = point1.Y.Offset - point2.Y.Offset
    local hypotenuse = math.sqrt(math.pow(x, 2) + math.pow(y, 2))
    local theta = math.atan2(y, x)
    return hypotenuse, theta
end

warn("v3")
local timeAccumulated = 0
RunService:BindToRenderStep(bindName, 200, function(dt)
    timeAccumulated += dt

    local radiansPerSecond = math.pi/4
    vpCamera.CFrame = CFrame.new() * CFrame.Angles(0, radiansPerSecond*timeAccumulated, 0) * CFrame.Angles(0, math.pi, 0) * CFrame.new(0, 0, vpCameraRadius)

    --Positions the overlay gui
    for _, area in infoTable do
        local ui = area.twoD
        local screenPosition : UDim2 = get2DPosition(area.threeD.Position, vpCamera)

        --positioning the circle
        local circlePosition : UDim2 = screenPosition
        ui.circle.Position = circlePosition

        --positioning the slot
        if area.intialSlotPosition == nil then
            area.intialSlotPosition = circlePosition  + UDim2.fromOffset(125 * ui.offset, -slotTemplate.AbsoluteSize.Y)
            ui.slot.Position = area.intialSlotPosition
        end
        

        --connecting a line between the circle and slot
        local hypotenuse, theta = findHypotenuseAndTheta(area.intialSlotPosition, circlePosition)
        ui.line.Size = UDim2.fromOffset(2, hypotenuse)
        ui.line.Position = circlePosition:Lerp(area.intialSlotPosition, 0.5)
        ui.line.Rotation = math.deg(theta) + 90
    end
end)

