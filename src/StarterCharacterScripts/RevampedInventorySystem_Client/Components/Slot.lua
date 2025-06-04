--!strict

local playerGui : PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local SlotTemplate : Frame = Templates:FindFirstChild("SlotTemplate") :: Frame
local InventoryState = require("./InventoryState")

local SlotType = require("./SlotType")
local WearableCategory = require("./WearableCategory")
local WearableSlotInfo = require("./WearableSlotInfo")
local WearItemStateMachine = require("./WearItemStateMachine")
local UnwearItemStateMachine = require("./UnwearItemStateMachine")
export type SlotType = SlotType.SlotType
local Hover = require("./Hover")
local Select = require("./Select")
local Config = require("./Config")
local UserInputService = game:GetService("UserInputService")
local Drag = require("./Drag")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}

local EquipToolStateMachine = require("./EquipToolStateMachine")

local FilledSlots : {SlotType.SlotType} = {}

local Slot = {}

local SlotStateChangedBindable: BindableEvent = Instance.new("BindableEvent")
Slot.StateChanged = SlotStateChangedBindable.Event

Slot.StateChanged:Connect(function(thisSlot: SlotType)  
    if thisSlot.state == "BeingSwapped" then
        print("BeingSwapped")
    end
end)

----    Local Functions

----    Methods

function Slot.new(slotType : "Hotbar" | "Inventory" | "Wearable", wearableCategory: WearableCategory.WearableCategoryType?) : SlotType.SlotType
    local slot = SlotTemplate:Clone()

    local self : SlotType.SlotType = {
        state = "Idle",
        _itself = slot :: Frame,
        _isEmpty = true :: boolean,
        InnerFrame = slot:FindFirstChild("innerFrame", true) :: Frame,
        ImageButton = slot:FindFirstChild("ImageButton", true) :: ImageButton,
        ActionIndicator = slot:FindFirstChild("ActionIndicator", true) :: ImageLabel,
        HotbarNumber = slot:FindFirstChild("HotbarNumber", true) :: TextLabel,
        Quantity = slot:FindFirstChild("Quantity", true) :: TextLabel,
        WearableCategory = wearableCategory,
        connections = {},
        tool = nil 
    }
    self.HotbarNumber.Visible = if slotType == "Hotbar" then true else false
    self._itself.Visible = true
    self.ImageButton.Visible = false
    self.ActionIndicator.Visible = false
    self.Quantity.Visible = false

    self.connections.hoverBegin = self._itself.MouseEnter:Connect(function(a0: number, a1: number)  
        Hover.applyEffect(self)
    end) 
    self.connections.hoverEnd = self._itself.MouseLeave:Connect(function(a0: number, a1: number)  
        Hover.removeEffect(self)
    end)

    return self
end

--[[
    Wrapper method for changing state
]]
function Slot.ChangeState(self: SlotType.SlotType, state: SlotType.SlotState)
    --fire bindable event when state changes
    if self.state ~= state then
        self.state = state
        SlotStateChangedBindable:Fire(self)
    end
end

function Slot.FillSlot(self : SlotType.SlotType, tool : Tool, itemType : string)
    Slot.ChangeState(self, "Filling")
    -- print("Filling slot: ", self.HotbarNumber.Text)
    self.Quantity.Visible = if itemType == "Misc" then true else false
    self.ImageButton.Image = tool.TextureId
    self.tool = tool
    self.ImageButton.Visible = true
    self._isEmpty = false

    if not self.WearableCategory then
        self.connections.EquipFromClick = self.ImageButton.MouseButton1Click:Connect(function(...: any) 
            if InventoryState.GetState() ~= "SwappingSlots" then
                EquipToolStateMachine.SetTargetTool(self)
            end
        end)
    end

    self.connections.DragFunctionality = self.ImageButton.MouseButton1Down:Connect(function()
        local startDrag: RBXScriptConnection?
    
        startDrag = UserInputService.InputChanged:Connect(function(inputObject: InputObject, a1: boolean)  
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                if startDrag then
                    startDrag:Disconnect()
                end
            end

            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            print("dragging")
            Drag.start(self)
            local connection
            connection = UserInputService.InputEnded:Connect(function(inputObject: InputObject, a1: boolean)  
                if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
                    connection:Disconnect()
                    -- reason for these cahced variables is because on touch inputs, hover coincides w/ drag via long presss
                    local cachedHoverCurrentSlot = Hover.currentSlot
                    local cachedHoverIsInInventory = Hover.IsInInventory
                    Drag.stop(self)
                    if cachedHoverCurrentSlot and cachedHoverCurrentSlot ~= self then
                        Slot.SwapSlots(self, cachedHoverCurrentSlot)    
                    elseif not cachedHoverIsInInventory and cachedHoverCurrentSlot == nil then
                        if self.state ~= "BeingSwapped" then
                            bindables.DropToolBindable:Fire(self.tool)
                        end
                    else
                        warn("doing nothing with dragged slot")                    
                    end
                end
            end)            
        end
        end)
    end)
    table.insert(FilledSlots, self)
    Slot.ChangeState(self, "Idle")
end

function Slot.EmptySlot(self : SlotType.SlotType)
    Slot.ChangeState(self, "Emptying")
    Select.removeEffect(self)
    Hover.removeEffect(self)
    self.Quantity.Visible = false
    self.ImageButton.Image = ""
    self.tool = nil
    self.ImageButton.Visible = false
    self._isEmpty = true
    for name, v in self.connections do
        if name ~= "hoverBegin" and name ~= "hoverEnd" then            
            v:Disconnect()
        end
    end
    table.remove(FilledSlots, table.find(FilledSlots, self))

    if self.WearableCategory then
        print(self.WearableCategory)
        self.ImageButton.Visible = true
        self.ImageButton.Image = WearableSlotInfo[self.WearableCategory].image
    end
    Slot.ChangeState(self, "Idle")
end

function Slot.GetSlotFromTool(tool : Tool) : SlotType.SlotType?
    for _, v in FilledSlots do
        if v.tool == tool then
            return v
        end
    end
    return nil
end

function Slot.SwapSlots(s1: SlotType.SlotType, s2: SlotType.SlotType)
    if s1.WearableCategory == nil and s2.WearableCategory == nil then
        if s2._itself.Parent ~= s1._itself.Parent then
            print("switching slot parents", s1._itself.Parent, s2._itself.Parent)
            local s2_savedParent = s2._itself.Parent
            s2._itself.Parent = s1._itself.Parent
            s1._itself.Parent = s2_savedParent
        end

        local s2LO = s2._itself.LayoutOrder
        local s1LO = s1._itself.LayoutOrder
        s2._itself.LayoutOrder = s1LO
        s2.HotbarNumber.Text = tostring(s1LO)
        s1._itself.LayoutOrder = s2LO
        s1.HotbarNumber.Text = tostring(s2LO)
    else
        --defining
        local wearableSlot: SlotType.SlotType
        local itemSlot: SlotType.SlotType
        --initializing
        if s1.WearableCategory and s2.WearableCategory == nil then
            wearableSlot = s1
            itemSlot = s2
        elseif s2.WearableCategory and s1.WearableCategory == nil then
            wearableSlot = s2
            itemSlot = s1
        end
        --logic
        Slot.ChangeState(wearableSlot, "BeingSwapped")
        Slot.ChangeState(itemSlot, "BeingSwapped")
        InventoryState.ChangeState("SwappingSlots")
        if wearableSlot.tool and itemSlot.tool then -- both are filled
            if itemSlot.tool:GetAttribute("WearableCategory") == wearableSlot.WearableCategory then 
                Slot.ChangeState(wearableSlot, "BeingSwapped")
                Slot.ChangeState(itemSlot, "BeingSwapped")
                InventoryState.ChangeState("SwappingSlots")
                local currentTool = EquipToolStateMachine.GetCurrentTool()
                -- if currentTool ~= itemSlot.tool
                EquipToolStateMachine.SetTargetTool(itemSlot)
                local wearableSlotTool = wearableSlot.tool
                Slot.EmptySlot(wearableSlot)
                Slot.FillSlot(wearableSlot, itemSlot.tool, "")
                Slot.EmptySlot(itemSlot)
                Slot.FillSlot(itemSlot, wearableSlotTool, "")
            end
        elseif wearableSlot.tool == nil and itemSlot.tool == nil then -- both are empty
            -- do fucking nothing
        elseif wearableSlot.tool == nil then -- wearable slot is empty, item slot is filled
            if itemSlot.tool:GetAttribute("WearableCategory") == wearableSlot.WearableCategory then
                local timeUntilWorn = WearItemStateMachine.SetTargetTool(itemSlot)
                print(timeUntilWorn)
                while timeUntilWorn > 0 do
                    timeUntilWorn -= task.wait()
                end
                Slot.FillSlot(wearableSlot, itemSlot.tool, "")
                Slot.EmptySlot(itemSlot)
            else
                print("This is the not the correct spot")
            end
        else -- itemSlot.tool == nil; wearable slot is filled, item slot is empty
            -- UnwearItemStateMachine.SetTargetTool(itemSlot)
            -- while itemSlot.tool:GetAttribute("State"):: WearItemStateMachine.itemStates ~= "Worn" do
            --     task.wait()
            -- end
            -- Slot.FillSlot(wearableSlot, itemSlot.tool, "")
            -- Slot.EmptySlot(itemSlot)
        end
        --make sure the statements above yields until wear/unwear process has been successfully completed, otherwise this'll bug out
        warn("Finished wearing process")
        Slot.ChangeState(wearableSlot, "Idle")
        Slot.ChangeState(itemSlot, "Idle")
        InventoryState.ChangeState("Idle")
    end
end

function Slot.destroy(self : SlotType.SlotType)
    Slot.ChangeState(self, "Destroying")
    self._itself:Destroy()
    for _, v in self.connections do
        v:Disconnect()
    end
    table.clear(self)
end

return Slot