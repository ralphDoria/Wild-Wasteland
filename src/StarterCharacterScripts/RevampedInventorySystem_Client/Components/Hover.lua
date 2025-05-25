local SlotType = require("./SlotType")
local TweenService = game:GetService("TweenService")

local player = game:GetService("Players").LocalPlayer
local playerGui : PlayerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local ItemInfoDisplayTempalte = Templates:FindFirstChild("ItemInfoDisplayTemplate")
local GuiService = game:GetService("GuiService")

local Hover = {}

Hover.currentSlot = nil
local itemInfoDisplays = {}

local function createItemInfoDisplay(slot: SlotType.SlotType)
    local clone: Frame = ItemInfoDisplayTempalte:Clone()
    local textbox = clone:FindFirstChildWhichIsA("TextBox", true)
    local tool = slot.tool :: Tool
    if textbox then
       textbox.Text = tool:GetAttribute("Description")  
    end
    local nameLabel = clone:FindFirstChildWhichIsA("TextLabel", true)
    if nameLabel then
        nameLabel.Text = tool.Name
    end
    clone.Visible = true
    clone.AnchorPoint = Vector2.new(0.5, 1)
    clone.Position = UDim2.fromOffset(
        slot._itself.AbsolutePosition.X - slot._itself.AnchorPoint.X*slot._itself.AbsoluteSize.X + 0.5*slot._itself.AbsoluteSize.X, 
        slot._itself.AbsolutePosition.Y - slot._itself.AnchorPoint.Y*slot._itself.AbsoluteSize.Y + GuiService:GetGuiInset().Y
    )
    clone.Parent = gui
    return clone
end

local function destroyItemInfoDisplay(itemInfoDisplay)
    itemInfoDisplay:Destroy()
end

function Hover.applyEffect(slot: SlotType.SlotType)
    Hover.currentSlot = slot

    TweenService:Create(
        slot.ImageButton, 
        TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge), 
        {Rotation = 180}
    ):Play()
    slot.ImageButton.Size = UDim2.fromScale(0.8, 0.8)

    itemInfoDisplays[slot] = createItemInfoDisplay(slot)
    -- -- for creating a delay before possibly showing info display
    -- task.spawn(function()
    --     task.wait(0.5)
    --     if Hover.currentSlot == slot then
            
    --     end
    -- end)
end

function Hover.removeEffect(slot: SlotType.SlotType)
    if Hover.currentSlot == slot then
        Hover.currentSlot = nil
    else
        --otherwise, it's been changed by Hover.applyEffect, and should avoid setting it to nil here to avoid race condition bugs
    end

    TweenService:Create(
        slot.ImageButton, 
        TweenInfo.new(0.2), 
        {Rotation = -180}
    ):Play()
    slot.ImageButton.Size = UDim2.fromScale(1, 1)

    local thisItemInfoDisplay = itemInfoDisplays[slot]
    if thisItemInfoDisplay then
        thisItemInfoDisplay:Destroy()
        itemInfoDisplays[slot] = nil
    end
end

return Hover