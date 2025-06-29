--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local PlaySound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

local ToolSystem_Storage = References_Inventory.ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}
local SFX = {
    hover = References_Inventory.Storage.SFX.hover
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local Type_Slot = require("./../Slot/Type_Slot")
local Type_Equipment = require("./../../CharacterSection/Components/Type_Equipment")
local EquipmentInitData = require("./../../CharacterSection/Components/EquipmentInitData")
local SlotObjectsCacher = require("./SlotObjectsCacher")
local Hover = require("./../Slot/Hover")
local Select = require("./../Slot/Select")
local Drag = require("./../Slot/Drag")
local ToolStateMachine = require("./../ToolStateMachine/Main_ToolStateMachine")
local handleDragDrop = require(InventoryScriptStorage.Components.Slot.handleDragDrop)

export type SlotObject = Type_Slot.SlotObject
export type State = Type_Slot.SlotState
local Slot = {}

local SlotStateChangedBindable: BindableEvent = Instance.new("BindableEvent")
Slot.StateChanged = SlotStateChangedBindable.Event

-- Slot.StateChanged:Connect(function(thisSlot: SlotObject)  
--     if thisSlot.State == "BeingSwapped" then
--         print("BeingSwapped")
--     end
-- end)

----    Local Functions

----    Methods

--[[
    For 
]]
function Slot.start()
    
end

function Slot.new(slotType : "Hotbar" | "Inventory" | "Wearable", wearableCategory: Type_Equipment.EquipmentCategory?) : Type_Slot.SlotObject
    local slot = References_Inventory.TemplateSlot:Clone()

    local self : Type_Slot.SlotObject = {
        State = "Idle",
        _itself = slot :: Frame,
        _isEmpty = true :: boolean,
        InnerFrame = slot:FindFirstChild("innerFrame", true) :: Frame,
        ImageButton = slot:FindFirstChild("ImageButton", true) :: ImageButton,
        ActionIndicator = slot:FindFirstChild("ActionIndicator", true) :: ImageLabel,
        HotbarNumber = slot:FindFirstChild("HotbarNumber", true) :: TextLabel,
        FilledSlotCounter = slot:FindFirstChild("FilledSlotCounter", true) :: TextLabel,
        Quantity = slot:FindFirstChild("Quantity", true) :: TextLabel,
        WearableCategory = wearableCategory,
        connections = {},
        tool = nil 
    }
    self.HotbarNumber.Visible = if slotType == "Hotbar" then true else false
    self.FilledSlotCounter.Visible = false
    self._itself.Visible = true
    self.ImageButton.Visible = false
    self.ActionIndicator.Visible = false
    self.Quantity.Visible = false

    self.connections.hoverBegin = self._itself.MouseEnter:Connect(function(a0: number, a1: number)  
        Hover.applyEffect(self)
        if Drag.currentSlot then
            PlaySound(SFX.hover)
        end
    end) 
    self.connections.hoverEnd = self._itself.MouseLeave:Connect(function(a0: number, a1: number)  
        Hover.removeEffect(self)
    end)
    self.connections.onDestroying = self._itself.Destroying:Connect(function(...: any)  
        Slot.destroy(self)
    end)

    table.insert(SlotObjectsCacher.InitializedSlots, self)

    return self
end

--[[
    Wrapper method for changing state
]]
function Slot.ChangeState(self: Type_Slot.SlotObject, state: Type_Slot.SlotState)
    --fire bindable event when state changes
    if self.State ~= state then
        self.State = state
        SlotStateChangedBindable:Fire(self, state)
    end
end

function Slot.FillSlot(self : Type_Slot.SlotObject, tool : Tool)
    Slot.ChangeState(self, "Filling")
    -- print("Filling slot: ", self.HotbarNumber.Text)
    -- self.Quantity.Visible = if itemType == "Misc" then true else false
    self.ImageButton.Image = tool.TextureId
    self.tool = tool
    self.ImageButton.Visible = true
    self._isEmpty = false

    if not self.WearableCategory and self._itself.Parent ~= References_Inventory.LootingEquipmentSlots 
        and self._itself.Parent and self._itself.Parent.Parent ~= References_Inventory.LootingScrollingFrame  then
        self.connections.EquipFromClick = self.ImageButton.MouseButton1Click:Connect(function(...: any) 
            assert(self.tool ~= nil)
            local state = self.tool:GetAttribute("State")
            warn("Checkpoint 1", state)
            if state == "Unequipping" or state == "Unequipped" then
                ToolStateMachine.SetTargets(self, "Idle")
            elseif state == "Equipping" or state == "Idle" then
                ToolStateMachine.SetTargets(self, "Unequipped")
            end
        end)
    end

    if self.WearableCategory and tool:HasTag("StorageWearable") then
        local FilledSlotCounter = self.FilledSlotCounter
        FilledSlotCounter.Visible = true

        local associatedSlotGroup: ObjectValue? = tool:FindFirstChildOfClass("ObjectValue")
        if associatedSlotGroup then

            local  connection
            associatedSlotGroup:GetPropertyChangedSignal("Value"):Connect(function()  
                if connection then
                    connection:Disconnect()
                end
                local slotGroupInstance = associatedSlotGroup.Value
                if slotGroupInstance then

                    FilledSlotCounter.Text = slotGroupInstance:GetAttribute("FilledSlotCounter_Client"):: string

                    connection = slotGroupInstance:GetAttributeChangedSignal("FilledSlotCounter_Client"):Connect(function()
                        FilledSlotCounter.Text = slotGroupInstance:GetAttribute("FilledSlotCounter_Client"):: string
                    end)
                else
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        else
            warn("ASSOCIATED SLOT GROUP NOT FOUND")
        end
    end

    self.connections.DragFunctionality = Drag.InitForSlot(self, function(hoverSlot, isOutsideInventory)
        handleDragDrop(self, isOutsideInventory, hoverSlot, Slot.ChangeState, Slot.FillSlot, Slot.EmptySlot)
    end)

    table.insert(SlotObjectsCacher.FilledSlots, self)
    Slot.ChangeState(self, "Idle")
end

function Slot.EmptySlot(self : Type_Slot.SlotObject?)
    if self == nil then 
        warn("Cannot empty slot, SlotObject is nil")
        return 
    end
    Slot.ChangeState(self, "Emptying")
    Select.removeEffect(self)
    Hover.removeEffect(self)
    self.Quantity.Visible = false
    self.FilledSlotCounter.Visible = false
    self.ImageButton.Image = ""
    self.tool = nil
    self.ImageButton.Visible = false
    self._isEmpty = true
    for name, v in self.connections do
        if name ~= "hoverBegin" and name ~= "hoverEnd" then            
            v:Disconnect()
        end
    end
    
    table.remove(SlotObjectsCacher.FilledSlots, table.find(SlotObjectsCacher.FilledSlots, self))

    if self.WearableCategory then
        self.ImageButton.Visible = true
        self.ImageButton.Image = EquipmentInitData[self.WearableCategory].image
    end
    Slot.ChangeState(self, "Idle")
end

function Slot.destroy(self : Type_Slot.SlotObject)
    table.remove(SlotObjectsCacher.InitializedSlots, table.find(SlotObjectsCacher.InitializedSlots, self))
    Slot.ChangeState(self, "Destroying")
    if self._itself.Parent ~= nil then
        self._itself:Destroy()    
    end
    for _, v in self.connections do
        v:Disconnect()
    end
    table.clear(self)
end

return Slot