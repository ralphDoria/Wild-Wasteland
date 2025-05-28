local player = game:GetService("Players").LocalPlayer
local playerGui : PlayerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame
local WearableSection : Frame = MainInventory:FindFirstChild("WearableSection") :: Frame
local Templates = WearableSection:FindFirstChild("Templates")
local circle = Templates:FindFirstChild("Circle")
local line = Templates:FindFirstChild("Line")
local WearableSlot = require("./WearableSlot")
local ViewportCharacter = require("./ViewportCharacter")
local ViewportFrame = WearableSection:FindFirstChildWhichIsA("ViewportFrame", true)
local RunService = game:GetService("RunService")
PointDimensionalConverter = require("./PointDimensionalConverter")

type x = {
    slot: WearableSlot.WearableSlotType, 
    circle: ImageLabel, 
    line: ImageLabel, 
    image: string,
    torsoOffset: CFrame,
    uiOffsetMultiplier: number
}

local slots: {x} = {
    Torso = {
        slot = nil,
        image = "rbxassetid://18790580783",
        torsoOffset = CFrame.new(),
        uiOffsetMultiplier = 1
    },
    Legs = {
        slot = nil, 
        image = "rbxassetid://18790582567",
        torsoOffset = CFrame.new(0, -2, 0),
        uiOffsetMultiplier = -1
    },
    Head = {
        slot = nil, 
        image = "rbxassetid://18790572259",
        torsoOffset = CFrame.new(0, 1.5, 0)
        ,
        uiOffsetMultiplier = 1
    },
    Feet = {
        slot = nil, 
        image = "rbxassetid://18790584454",
        torsoOffset = CFrame.new(0, -3, 0),
        uiOffsetMultiplier = 1
    },
    Backpack = {
        slot = nil, 
        image = "rbxassetid://109883323088072",
        torsoOffset = CFrame.new(0, 0, 0.5),
        uiOffsetMultiplier = -1
    },
}

local WearableInterface = {}

function WearableInterface.initialize(character: Model)
    -- make sure character is in viewport frame first
    task.wait(0.5)
    local vpCharObj = ViewportCharacter.handleCharacter(ViewportFrame, character)

    for _, v in slots do
        v.slot = WearableSlot.new()
        v.slot.ImageButton.Image = v.image
        v.slot.ImageButton.Rotation = 0
        v.slot.ImageButton.Visible = true
        v.slot._itself.Parent = gui
        v.circle = circle:Clone()
        v.circle.Visible = true
        v.circle.Parent = gui
        v.line = line:Clone()
        v.line.Visible = true
        v.line.Parent = gui
    end

    -- based off character's torso CFrame and offsets from that, 
    RunService.RenderStepped:Connect(function(dt: number)  
        local torso: BasePart = vpCharObj.Viewmodel:FindFirstChild("Torso") :: BasePart
        if torso then
            for k, v in slots do
                local screenPosition : UDim2 = PointDimensionalConverter.get2DPosition((torso.CFrame * v.torsoOffset).Position, vpCharObj.Camera, ViewportFrame)

                --positioning the circle
                local circlePosition : UDim2 = screenPosition
                v.circle.Position = circlePosition

                --positioning the slot
                v.slot._itself.AnchorPoint = Vector2.new(0.5, 0.5)
                v.slot._itself.Position = circlePosition  + UDim2.fromOffset(v.slot._itself.AbsoluteSize.Y * v.uiOffsetMultiplier, -v.slot._itself.AbsoluteSize.Y)
                

                --connecting a line between the circle and slot
                local hypotenuse, theta = PointDimensionalConverter.findHypotenuseAndTheta(v.slot._itself.Position, circlePosition)
                v.line.Size = UDim2.fromOffset(2, hypotenuse)
                v.line.Position = circlePosition:Lerp(v.slot._itself.Position, 0.5)
                v.line.Rotation = math.deg(theta) + 90
            end 
        end
    end)
end

return WearableInterface