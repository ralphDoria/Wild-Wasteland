local SlotType = require("./SlotType")
local Config = require("./Config")

local player = game:GetService("Players").LocalPlayer
local playerGui : PlayerGui = player:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local ItemInfoDisplayTempalte = Templates:FindFirstChild("ItemInfoDisplayTemplate")
local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame

local Hover = {}

Hover.currentSlot = nil
SlotHoveredChangedBindable = Instance.new("BindableEvent")
SlotHoveredChanged = SlotHoveredChangedBindable.Event

Hover.IsInInventory = false

MainInventory.MouseEnter:Connect(function(a0: number, a1: number)  
    Hover.IsInInventory = true
end)

MainInventory.MouseLeave:Connect(function(a0: number, a1: number)  
    Hover.IsInInventory = false
end)

local itemInfoDisplays: {[SlotType.SlotType]: Frame} = {}

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
    clone.AnchorPoint = Vector2.new(0.5, 1)
    clone.Position = UDim2.fromOffset(
        slot._itself.AbsolutePosition.X - slot._itself.AnchorPoint.X*slot._itself.AbsoluteSize.X + 0.5*slot._itself.AbsoluteSize.X, 
        slot._itself.AbsolutePosition.Y - slot._itself.AnchorPoint.Y*slot._itself.AbsoluteSize.Y + GuiService:GetGuiInset().Y
    )

    clone.Visible = true
    clone.Parent = gui
    local finalSize = UDim2.new(0, clone.AbsoluteSize.X, 0, clone.AbsoluteSize.Y)
    clone.AutomaticSize = Enum.AutomaticSize.None
    clone.Size = UDim2.new(0, clone.AbsoluteSize.X, 0, 0)
    TweenService:Create(clone, TweenInfo.new(0.1), {Size = finalSize}):Play()
    return clone
end

local function destroyItemInfoDisplay(itemInfoDisplay)
    itemInfoDisplay:Destroy()
end

function Hover.applyEffect(slot: SlotType.SlotType)
    if Hover.currentSlot ~= slot then
        Hover.currentSlot = slot
        SlotHoveredChangedBindable:Fire()
        print("Hover.currentSlot: ", if Hover.currentSlot then Hover.currentSlot.HotbarNumber.Text else nil)
    end

    if not slot._isEmpty then
        -- for creating a delay before possibly showing info display
        task.spawn(function()
            local accumulatedTime = 0
            while Hover.currentSlot == slot do
                accumulatedTime += task.wait()
                if accumulatedTime >= Config.KBM_Touch.dragThreshold then
                    itemInfoDisplays[slot] = createItemInfoDisplay(slot)
                    break
                end
            end
        end)

        if slot.WearableCategory == nil then 
            TweenService:Create(
                slot.ImageButton, 
                TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge), 
                {Rotation = 180}
            ):Play()
            slot.ImageButton.Size = UDim2.fromScale(0.8, 0.8)
        end
    end
end

function Hover.removeEffect(slot: SlotType.SlotType)
    if Hover.currentSlot == slot then
        Hover.currentSlot = nil
    else
        --otherwise, it's been changed by Hover.applyEffect, and should avoid setting it to nil here to avoid race condition bugs
    end

    for _, v in itemInfoDisplays do
        v:Destroy()
    end 

    if not slot._isEmpty then

        if slot.WearableCategory == nil then 
            TweenService:Create(
                slot.ImageButton, 
                TweenInfo.new(0.2), 
                {Rotation = -180}
            ):Play()
            slot.ImageButton.Size = UDim2.fromScale(1, 1)
        end
    end
end

return Hover