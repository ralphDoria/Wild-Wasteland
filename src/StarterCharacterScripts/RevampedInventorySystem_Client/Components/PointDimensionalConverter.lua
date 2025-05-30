local GuiService = game:GetService("GuiService")

local PointDimensionalConverter = {}

--[[
    VERY IMPORTANT: THIS FUNCTION RETURNS 2D POSITION IN ABSOLUTE POSITION RELATIVE TO (0,0), MEAINING
    THE ELEMENTS YOU ARE POSITIONING SHOULDN'T BE PARENTED TO ANY OTHER OBJECT
]]
function PointDimensionalConverter.get2DPosition(Position: Vector3, camera : Camera, vpFrame: ViewportFrame?) : UDim2
	local ScreenPosition : Vector3, inView : boolean = camera:WorldToViewportPoint(Position)
	local ScreenSize : Vector2 = camera.ViewportSize

	if inView then
        if camera == workspace.CurrentCamera then
            local Vector2Position = Vector2.new(math.clamp(ScreenPosition.X, 0, ScreenSize.X), math.clamp(ScreenPosition.Y, 0, ScreenSize.Y))
            return UDim2.fromOffset(Vector2Position.X, Vector2Position.Y)
        else
            assert(vpFrame ~= nil, "If this function is being called w/ a camera other than the one in workspace, then you must also pass a viewport frame")
            local xOffset = vpFrame.AbsolutePosition.X + ScreenPosition.X * vpFrame.AbsoluteSize.X
            local yOffset = vpFrame.AbsolutePosition.Y + ScreenPosition.Y * vpFrame.AbsoluteSize.Y
            local pos = UDim2.fromOffset(xOffset, yOffset)
            --need to manually take into account gui inset
            pos = pos + UDim2.fromOffset(GuiService:GetGuiInset().X, GuiService:GetGuiInset().Y)
            return pos
        end
	else
		local Vector2Position = Vector2.new(math.clamp(ScreenPosition.X, 0, ScreenSize.X), math.clamp(ScreenPosition.Y, 0, ScreenSize.Y))
		local scaleX = Vector2Position.X / ScreenSize.X
		local scaleY = Vector2Position.Y / ScreenSize.Y
		return UDim2.fromOffset(scaleX, scaleY)
	end
end

function PointDimensionalConverter.findHypotenuseAndTheta(point1: UDim2, point2 : UDim2): (number, number)
    local x = point1.X.Offset - point2.X.Offset
    local y = point1.Y.Offset - point2.Y.Offset
    local hypotenuse = math.sqrt(math.pow(x, 2) + math.pow(y, 2))
    local theta = math.atan2(y, x)
    return hypotenuse, theta
end

return PointDimensionalConverter