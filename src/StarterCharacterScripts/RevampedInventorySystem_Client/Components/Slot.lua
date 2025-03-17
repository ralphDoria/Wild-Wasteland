--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bindables : {[string] : BindableEvent} = {
    toggleEquip = ReplicatedStorage.ToolSystem_Storage.Shared:FindFirstChild("toggleEquip", true)
}

export type SlotType = {
    _itself : Frame,
    _isEmpty : boolean,
    InnerFrame : Frame,
    ImageButton : ImageButton,
    DropLabel : TextLabel,
    HotbarNumber : TextLabel,
    Quantity : TextLabel,
    tool : Tool?
}

local Slot = {}

----    Local Functions

----    Methods

function Slot.new(slot : Frame, slotType : "Hotbar" | "Inventory") : SlotType

    local self : SlotType = {
        _itself = slot :: Frame,
        _isEmpty = true :: boolean,
        InnerFrame = slot:FindFirstChild("innerFrame", true) :: Frame,
        ImageButton = slot:FindFirstChild("ImageButton", true) :: ImageButton,
        DropLabel = slot:FindFirstChild("DropLabel", true) :: TextLabel,
        HotbarNumber = slot:FindFirstChild("HotbarNumber", true) :: TextLabel,
        Quantity = slot:FindFirstChild("Quantity", true) :: TextLabel,
        tool = nil 
    }
    self.HotbarNumber.Visible = if slotType == "Hotbar" then true else false
    self._itself.Visible = true
    self.ImageButton.Visible = false
    self.DropLabel.Visible = false
    self.Quantity.Visible = false
    return self

end

function Slot.FillSlot(self : SlotType, tool : Tool, itemType : string)
    print("Filling slot: ", self.HotbarNumber.Text)
    self.Quantity.Visible = if itemType == "Misc" then true else false
    self.ImageButton.Image = tool.TextureId
    self.tool = tool
    self.ImageButton.Visible = true
    self._isEmpty = false
    self.ImageButton.MouseButton1Click:Connect(function()
        Bindables.toggleEquip:Fire(self.tool)
    end)
end

function Slot.EmptySlot(self : SlotType)
    self.Quantity.Visible = false
    self._isEmpty = true
end

function Slot.destroy(self : SlotType)
    self._itself:Destroy()
    table.clear(self)
end

return Slot