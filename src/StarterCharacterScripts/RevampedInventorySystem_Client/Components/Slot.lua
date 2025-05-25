--!strict

local SlotType = require("./SlotType")
export type SlotType = SlotType.SlotType
local Hover = require("./Hover")
local Select = require("./Select")

local EquipToolStateMachine = require("./EquipToolStateMachine")

local FilledSlots : {SlotType.SlotType} = {}

local Slot = {}
----    Local Functions

----    Methods

function Slot.new(slot : Frame, slotType : "Hotbar" | "Inventory") : SlotType.SlotType

    local self : SlotType.SlotType = {
        _itself = slot :: Frame,
        _isEmpty = true :: boolean,
        InnerFrame = slot:FindFirstChild("innerFrame", true) :: Frame,
        ImageButton = slot:FindFirstChild("ImageButton", true) :: ImageButton,
        DropLabel = slot:FindFirstChild("DropLabel", true) :: TextLabel,
        HotbarNumber = slot:FindFirstChild("HotbarNumber", true) :: TextLabel,
        Quantity = slot:FindFirstChild("Quantity", true) :: TextLabel,
        connections = {},
        tool = nil 
    }
    self.HotbarNumber.Visible = if slotType == "Hotbar" then true else false
    self._itself.Visible = true
    self.ImageButton.Visible = false
    self.DropLabel.Visible = false
    self.Quantity.Visible = false
    return self

end

function Slot.FillSlot(self : SlotType.SlotType, tool : Tool, itemType : string)
    -- print("Filling slot: ", self.HotbarNumber.Text)
    self.Quantity.Visible = if itemType == "Misc" then true else false
    self.ImageButton.Image = tool.TextureId
    self.tool = tool
    self.ImageButton.Visible = true
    self._isEmpty = false
    self.connections.equipByClick = self.ImageButton.MouseButton1Click:Connect(function()
        EquipToolStateMachine.SetTargetTool(self)
    end)
    self.connections.hoverBegin = self._itself.MouseEnter:Connect(function(a0: number, a1: number)  
        Hover.applyEffect(self)
    end)
    self.connections.hoverEnd = self._itself.MouseLeave:Connect(function(a0: number, a1: number)  
        Hover.removeEffect(self)
    end)
    table.insert(FilledSlots, self)
end

function Slot.EmptySlot(self : SlotType.SlotType)
    Select.removeEffect(self)
    self.Quantity.Visible = false
    self.ImageButton.Image = ""
    self.tool = nil
    self.ImageButton.Visible = false
    self._isEmpty = true
    for _, v in self.connections do
        v:Disconnect()
    end
    table.remove(FilledSlots, table.find(FilledSlots, self))
end

function Slot.GetSlotFromTool(tool : Tool) : SlotType.SlotType?
    for _, v in FilledSlots do
        if v.tool == tool then
            return v
        end
    end
    return nil
end

function Slot.destroy(self : SlotType.SlotType)
    self._itself:Destroy()
    for _, v in self.connections do
        v:Disconnect()
    end
    table.clear(self)
end

return Slot