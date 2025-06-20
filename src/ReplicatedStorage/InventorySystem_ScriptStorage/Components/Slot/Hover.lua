local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local Type_Slot = require(ScriptStorage.Components.Slot.Type_Slot)

local Hover = {}

Hover.currentSlot = nil
SlotHoveredChangedBindable = Instance.new("BindableEvent")
SlotHoveredChanged = SlotHoveredChangedBindable.Event

Hover.InDropArea = false

References_Inventory.RunService.RenderStepped:Connect(function(a0: number)  
    local mousePos = References_Inventory.UserInputService:GetMouseLocation()
    local guis = References_Inventory.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y - References_Inventory.GuiService:GetGuiInset().Y)
    local filteredGuis = {}

    for _, v in guis do 
        if v.Parent == References_Inventory.InventoryScreenGui and v.Name ~= "innerFrame" then
            table.insert(filteredGuis, v)
        end
    end

    if filteredGuis[1] == References_Inventory.DropArea then 
        Hover.InDropArea = true 
    else
        Hover.InDropArea = false
    end
    -- print(Hover.InDropArea, filteredGuis)
end)

local itemInfoDisplays: {[Type_Slot.SlotObject]: Frame} = {}

local function createItemInfoDisplay(slot: Type_Slot.SlotObject)
    local clone: Frame = References_Inventory.TemplateItemInfoDisplay:Clone()
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
        slot._itself.AbsolutePosition.Y - slot._itself.AnchorPoint.Y*slot._itself.AbsoluteSize.Y + References_Inventory.GuiService:GetGuiInset().Y
    )

    clone.Visible = true
    clone.Parent = References_Inventory.InventoryScreenGui
    local finalSize = UDim2.new(0, clone.AbsoluteSize.X, 0, clone.AbsoluteSize.Y)
    clone.AutomaticSize = Enum.AutomaticSize.None
    clone.Size = UDim2.new(0, clone.AbsoluteSize.X, 0, 0)
    References_Inventory.TweenService:Create(clone, TweenInfo.new(0.1), {Size = finalSize}):Play()
    return clone
end

local function destroyItemInfoDisplay(itemInfoDisplay)
    itemInfoDisplay:Destroy()
end

function Hover.applyEffect(slot: Type_Slot.SlotObject)
    if Hover.currentSlot ~= slot then
        Hover.currentSlot = slot
        SlotHoveredChangedBindable:Fire()
        -- print("Hover.currentSlot: ", if Hover.currentSlot then Hover.currentSlot.HotbarNumber.Text else nil)
    end

    if not slot._isEmpty then
        -- for creating a delay before possibly showing info display
        task.spawn(function()
            local accumulatedTime = 0
            while Hover.currentSlot == slot do
                accumulatedTime += task.wait()
                if accumulatedTime >= 0.5 then
                    itemInfoDisplays[slot] = createItemInfoDisplay(slot)
                    break
                end
            end
        end)

        if slot.WearableCategory == nil then 
            References_Inventory.TweenService:Create(
                slot.ImageButton, 
                TweenInfo.new(10, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge), 
                {Rotation = 180}
            ):Play()
            slot.ImageButton.Size = UDim2.fromScale(0.8, 0.8)
        end
    end
end

function Hover.removeEffect(slot: Type_Slot.SlotObject)
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
            References_Inventory.TweenService:Create(
                slot.ImageButton, 
                TweenInfo.new(0.2), 
                {Rotation = -180}
            ):Play()
            slot.ImageButton.Size = UDim2.fromScale(1, 1)
        end
    end
end

return Hover