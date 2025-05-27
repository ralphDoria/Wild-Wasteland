local SlotType = require("./SlotType")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Drag = {}

local currentSlotBeingDragged: SlotType.SlotType
local currentGhostSlots = {}

local function createGhostSlot(slot: SlotType.SlotType)
    print("making ghost template")
    local ghostSlot = slot.InnerFrame:Clone()
    ghostSlot:FindFirstChild("HotbarNumber"):Destroy()
    ghostSlot:FindFirstChildOfClass("ImageButton").ImageTransparency = 0
    ghostSlot.Size = UDim2.fromOffset(slot.InnerFrame.AbsoluteSize.X, slot.InnerFrame.AbsoluteSize.X)
    local mousePosInVector2 : Vector2 = UserInputService:GetMouseLocation()
    ghostSlot.Position = UDim2.fromOffset(mousePosInVector2.X, mousePosInVector2.Y)
    ghostSlot.AnchorPoint = Vector2.new(0.5, 0.5)
    ghostSlot.Parent = slot._itself:FindFirstAncestorWhichIsA("ScreenGui")
    return ghostSlot
end

function Drag.start(slot: SlotType.SlotType)
    slot._itself.Interactable = false
    slot.ImageButton.ImageTransparency = 1
    local ghostSlot = createGhostSlot(slot)
    table.insert(currentGhostSlots, ghostSlot)
    currentSlotBeingDragged = slot
    RunService:BindToRenderStep("Drag", 201, function(delta: number)  
        local mousePosInVector2 : Vector2 = UserInputService:GetMouseLocation()
        ghostSlot.Position = ghostSlot.Position:Lerp(UDim2.fromOffset(mousePosInVector2.X, mousePosInVector2.Y), 0.3)
    end)
end

function Drag.stop(slot: SlotType.SlotType)
    slot._itself.Interactable = true
    slot.ImageButton.ImageTransparency = 0
    RunService:UnbindFromRenderStep("Drag")
    for _, v in currentGhostSlots do
        v:Destroy()
    end
end

return Drag