local wearableAreas = workspace:FindFirstChild("wearableAreas", true)
local RunService = game:GetService("RunService")
local bindName = "wearableUISlots"
local player = game:GetService("Players").LocalPlayer
local screenGui : ScreenGui = player.PlayerGui:WaitForChild("3Dto2D")
local circleTemplate = screenGui:FindFirstChild("Circle")
local slotTemplate = screenGui:FindFirstChild("Square")
local lineTemplate = screenGui:FindFirstChild("Line")
local infoTable = {
    Head = {
        threeD = wearableAreas:WaitForChild("Head"),
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = 1
        }
    },
    Torso = {
        threeD = wearableAreas:WaitForChild("Torso"),
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = -1
        }
    },
    Legs = {
        threeD = wearableAreas:WaitForChild("Legs"),
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = 1
        }
    },
    Feet = {
        threeD = wearableAreas:WaitForChild("Feet"),
        twoD = {
            circle = circleTemplate:Clone(),
            slot = slotTemplate:Clone(),
            line = lineTemplate:Clone(),
            offset = -1
        }
    }
}

for _, area in infoTable do
    for _, uiElement in area.twoD do
        if type(uiElement) ~= "number" then
            uiElement.Parent = screenGui
        end
    end
end

local function get2DPosition (Position: Vector3) : UDim2
	local ScreenPosition, inView = workspace.CurrentCamera:WorldToViewportPoint(Position)
	local ScreenSize = workspace.CurrentCamera.ViewportSize
	
	if inView then
		local Vector2Position = Vector2.new(math.clamp(ScreenPosition.X, 0, ScreenSize.X), math.clamp(ScreenPosition.Y, 0, ScreenSize.Y))
		return UDim2.fromOffset(Vector2Position.X, Vector2Position.Y)
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
    local hypotenuse = math.pow(math.pow(x, 2) + math.pow(y, 2), 1/2)
    local theta = math.tan(y/x)
    return hypotenuse, theta
end

RunService:BindToRenderStep(bindName, 200, function()
    for _, area in infoTable do
        local ui = area.twoD
        local screenPosition : UDim2 = get2DPosition(area.threeD.Position)

        --positioning the circle
        local circlePosition : UDim2 = screenPosition
        ui.circle.Position = circlePosition

        --positioning the slot
        local slotPosition : UDim2 = circlePosition  + UDim2.fromOffset(100 * ui.offset, -slotTemplate.AbsoluteSize.Y)
        ui.slot.Position = slotPosition

        --connecting a line between the circle and slot
        local hypotenuse, theta = findHypotenuseAndTheta(slotPosition, circlePosition)
        ui.line.Size = UDim2.fromOffset(2, hypotenuse)
        ui.line.Position = circlePosition:Lerp(slotPosition, 0.5)
        ui.line.Rotation = math.deg(theta) + 90
    end
end)
