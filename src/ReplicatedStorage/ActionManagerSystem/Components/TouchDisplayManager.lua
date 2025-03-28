local Players = game:GetService("Players")
local player = Players.LocalPlayer :: Player
local playerGui = player:WaitForChild("PlayerGui")
local actionGui = playerGui:WaitForChild("ActionGui2")
local instances = actionGui:FindFirstChild("Instances")
local RunService = game:GetService("RunService")
local touchDisplay = actionGui.TouchDisplay
local jumpButtonPlaceholder = touchDisplay.Buttons
local TouchButtonTemplate : ImageButton = instances.TouchButton
local ImageRectOffset : {[string] : Vector2}= {
    default = Vector2.new(1, 146),
    activated = Vector2.new(146, 146) 
}
local CircularProgressBarManager = require("../../Utility/CircularProgressBarManager")

type binding = {
	connections: {RBXScriptConnection},
	keyboardAndMouseInput: Enum.KeyCode | Enum.UserInputType,
	gamepadInput: Enum.KeyCode | Enum.UserInputType,
	frame: Frame,
	touchButton: ImageButton,
	progressBarConnection: RBXScriptConnection?
}

local TouchDisplayManager = {
    _initialized = false
}

function TouchDisplayManager.CreateTouchButton(
    binding, 
    displayOrder: number,
	toggle: boolean?,
    cooldownTime: number?,
	touchButtonImageId : string
) : ImageButton
    local touchButton = TouchButtonTemplate:Clone()
    touchButton.Image = touchButtonImageId
    touchButton.ImageRectOffset = ImageRectOffset.default
    touchButton.ImageRectSize = Vector2.new(144, 144)
    touchButton.Parent = touchDisplay:FindFirstChild("Buttons")

    local xScale : number = if displayOrder % 2 == 0 then 0 else -1.1
    local yLevel: number = math.floor(displayOrder/2)
    local yScale : number = -(yLevel + if yLevel == 0 then 0 else 0.1)
    touchButton.Position = UDim2.fromScale(xScale, yScale)

    -- Touch button connections
    if toggle == nil then
        table.insert(
                binding.connections,
                touchButton.InputBegan:Connect(function(inputObject)
                    if inputObject.UserInputType == Enum.UserInputType.Touch then
                        touchButton.ImageRectOffset = ImageRectOffset.activated
                    end
                end)
        )
        table.insert(
            binding.connections,
            touchButton.InputEnded:Connect(function(inputObject)
                if inputObject.UserInputType == Enum.UserInputType.Touch then
                    touchButton.ImageRectOffset = ImageRectOffset.default
                end
            end)
        )
    else
        table.insert(
                binding.connections,
                touchButton.InputBegan:Connect(function(inputObject)
                    if inputObject.UserInputType == Enum.UserInputType.Touch then
                        if toggle then
                            toggle = false
                            touchButton.ImageRectOffset = ImageRectOffset.default
                        else
                            toggle = true
                            touchButton.ImageRectOffset = ImageRectOffset.activated
                        end
                    end
                end)
        )
    end

    if cooldownTime then
        table.insert(
            binding.connections,
            CircularProgressBarManager.CreateProgressBar(touchButton, Color3.fromRGB(217, 145, 0))
        )
    end
 
    return touchButton
end

function TouchDisplayManager.updatePositionAndScale()
    local screenSize = actionGui.AbsoluteSize -- Absolute Size of the screen.
    local minAxis = math.min(screenSize.X, screenSize.Y)
    local isSmallScreen = minAxis <= 500 -- Is the screen to small for big mobile buttons?
    local jumpButtonSize = isSmallScreen and 70 or 120 -- Gets the size of the jump button.
    jumpButtonPlaceholder.Size = UDim2.new(0, jumpButtonSize, 0, jumpButtonSize)
    jumpButtonPlaceholder.Position = isSmallScreen and UDim2.new(1, -(jumpButtonSize*1.5-10), 1, -jumpButtonSize - 20) or UDim2.new(1, -(jumpButtonSize*1.5-10), 1, -jumpButtonSize * 1.75)
end

function TouchDisplayManager.getTouchDisplay(): Frame
    return touchDisplay
end

function TouchDisplayManager.toggleButtonImage(imageButton: ImageButton, toggle: boolean)
    if toggle then
        imageButton.ImageRectOffset = ImageRectOffset.activated
    else
        imageButton.ImageRectOffset = ImageRectOffset.default
    end
end

function TouchDisplayManager._initialize()
    assert(not TouchDisplayManager._initialized, "ActionManager already initialized!")
    assert(RunService:IsClient(), "ActionManager can only be used on the client!")
    TouchDisplayManager._initialized = true
end

TouchDisplayManager._initialize()

return TouchDisplayManager