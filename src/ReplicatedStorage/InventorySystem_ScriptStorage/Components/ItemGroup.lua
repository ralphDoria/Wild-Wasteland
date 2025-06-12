--!strict

local playerGui : PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local MainInventory : Frame = gui:FindFirstChild("MainInventory") :: Frame
local StoreSection : ScrollingFrame = MainInventory:FindFirstChild("StoreSection", true) :: ScrollingFrame
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local ItemGroupTemplate : Frame = Templates:FindFirstChild("ItemGroupTemplate") :: Frame
local Slot = require("./Slot/Slot")
local FilledSlotsTracker = require("./Slot/FilledSlotsTracker")

export type ItemGroupState = "Empty" | "Filled"

export type ItemGroupObject = {
    _itself: Frame,
    State: ItemGroupState,
    Name: string,
    Space: number,
    ItemSlots: {[Frame]: Slot.SlotType},
    ItemsFrame: Frame,
    Connections: {RBXScriptConnection}
}

local ItemGroup = {}
ItemGroup.__index = ItemGroup

function ItemGroup.new(name: string, space: number): ItemGroupObject
    local clone = ItemGroupTemplate:Clone()
    local itemsFrame = clone:FindFirstChildOfClass("Frame"):: Frame
    local self: ItemGroupObject = {
        _itself = clone,
        State = "Empty",
        ItemsFrame = itemsFrame,
        Space = space,
        Name = name,
        ItemSlots = {},
        Connections = {}
    }

    ItemGroup._initialize(self)

    return self
end

function ItemGroup._initialize(self: ItemGroupObject)
    for i = 1, self.Space, 1 do
        local slot = Slot.new("Inventory")
        slot._itself.LayoutOrder = i
        slot._itself.Parent = self._itself:FindFirstChildOfClass("Frame")
        self.ItemSlots[slot._itself] = slot
    end
    local textLabel = self._itself:FindFirstChildOfClass("TextLabel"):: TextLabel
    textLabel.Text = self.Name
    self._itself.Visible = true
    self._itself.Parent = StoreSection
    table.insert(
        self.Connections,
        self.ItemsFrame.ChildAdded:Connect(function(child: Instance)  
            assert(child:IsA("Frame"))
            self.ItemSlots[child] = FilledSlotsTracker.GetSlotFromInstanceSlot(child):: Slot.SlotType
        end)
    )
    table.insert(
        self.Connections,
        self.ItemsFrame.ChildRemoved:Connect(function(child: Instance)  
            assert(child:IsA("Frame"))
            self.ItemSlots[child] = nil
        end)
    )
end


function ItemGroup.Destroy(self: ItemGroupObject)
    for _, v in self.Connections do
        v:Disconnect()
    end
    task.defer(function() -- have to defer because Empty Slot will be called, and we need that to run before we call destroy on the slots
        -- for _, v in self.ItemSlots do
        --     Slot.destroy(v)
        -- end
        table.clear(self.Connections)
        self._itself:Destroy()
        table.clear(self)
    end)
end

return ItemGroup