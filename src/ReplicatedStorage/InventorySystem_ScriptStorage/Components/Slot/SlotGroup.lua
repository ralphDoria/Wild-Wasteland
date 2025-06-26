--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local Slot = require("./Slot")
local SlotObjectsCacher = require("./SlotObjectsCacher")
local Types_LootSystem = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.Types_LootSystem)

export type ItemGroupState = "Empty" | "Filled"

export type ItemGroupObject = {
    _itself: Frame,
    State: ItemGroupState,
    Name: string,
    Space: number,
    ItemSlots: {[Frame]: Slot.SlotObject},
    ItemsFrame: Frame,
    Connections: {RBXScriptConnection}
}

local SlotGroup = {}
SlotGroup.__index = SlotGroup

function SlotGroup.new(name: string, space: number, lootData: Types_LootSystem.StandardLootableObject?): ItemGroupObject
    local clone = References_Inventory.TemplateSlotGroup:Clone()
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

    SlotGroup._initialize(self, lootData)

    return self
end

function SlotGroup._initialize(self: ItemGroupObject, lootData: Types_LootSystem.StandardLootableObject?)
    for i = 1, self.Space, 1 do
        local slot = Slot.new("Inventory")
        slot._itself.LayoutOrder = i

        local tool = if lootData and lootData.items[i].tool then lootData.items[i].tool else nil
        if tool then
            Slot.FillSlot(slot, tool, "")
        end
        
        slot._itself.Parent = self._itself:FindFirstChildOfClass("Frame")
        self.ItemSlots[slot._itself] = slot
    end
    
    local textLabel = self._itself:FindFirstChildOfClass("TextLabel"):: TextLabel
    textLabel.Text = self.Name
    self._itself.Visible = true
    self._itself.Parent = References_Inventory.InventoryScrollingFrame
    table.insert(
        self.Connections,
        self.ItemsFrame.ChildAdded:Connect(function(child: Instance)  
            assert(child:IsA("Frame"))
            self.ItemSlots[child] = SlotObjectsCacher.GetSlotFromInstanceSlot(child):: Slot.SlotObject
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

function SlotGroup.Destroy(self: ItemGroupObject)
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

return SlotGroup