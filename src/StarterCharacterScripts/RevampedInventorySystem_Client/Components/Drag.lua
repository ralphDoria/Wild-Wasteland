local SlotType = require("./SlotType")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
Hover = require("./Hover")

local Drag = {}

Drag.currentSlot = nil
local currentGhostSlots = {}

local function createGhostSlot(slot: SlotType.SlotType)
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
    -- slot._itself.Interactable = false
    slot.ImageButton.ImageTransparency = 1
    local ghostSlot = createGhostSlot(slot)
    table.insert(currentGhostSlots, ghostSlot)
    Drag.currentSlot = slot

    RunService:BindToRenderStep("Drag", 201, function(delta: number)  
        --Positioning drag slot
        local mousePosInVector2 : Vector2 = UserInputService:GetMouseLocation()
        ghostSlot.Position = ghostSlot.Position:Lerp(UDim2.fromOffset(mousePosInVector2.X, mousePosInVector2.Y), 0.3)

        --managing slot action indicators
        if Hover.currentSlot and Hover.currentSlot ~= slot then
            ghostSlot.ActionIndicator.Image = slot.ActionIndicator:GetAttribute("swapImage") :: string
            ghostSlot.ActionIndicator.Visible = true
        elseif not Hover.IsInInventory and Hover.currentSlot == nil then
            ghostSlot.ActionIndicator.Image = slot.ActionIndicator:GetAttribute("dropImage") :: string
            ghostSlot.ActionIndicator.Visible = true
        else
            ghostSlot.ActionIndicator.Visible = false                 
        end
    end)
end

function Drag.stop(slot: SlotType.SlotType)
    -- slot._itself.Interactable = true
    slot.ImageButton.ImageTransparency = 0
    RunService:UnbindFromRenderStep("Drag")
    for _, v in currentGhostSlots do
        v:Destroy()
    end
    Drag.currentSlot = nil
end

return Drag