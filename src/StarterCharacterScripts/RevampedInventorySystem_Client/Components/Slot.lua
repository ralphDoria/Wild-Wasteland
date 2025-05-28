--!strict

local playerGui : PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local SlotTemplate : Frame = Templates:FindFirstChild("SlotTemplate") :: Frame

local SlotType = require("./SlotType")
export type SlotType = SlotType.SlotType
local Hover = require("./Hover")
local Select = require("./Select")
local Config = require("./Config")
local UserInputService = game:GetService("UserInputService")
local Drag = require("./Drag")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable
}

local EquipToolStateMachine = require("./EquipToolStateMachine")

local FilledSlots : {SlotType.SlotType} = {}

local Slot = {}
----    Local Functions

----    Methods

function Slot.new(slotType : "Hotbar" | "Inventory" | "Wearable") : SlotType.SlotType

    local slot = SlotTemplate:Clone()

    local self : SlotType.SlotType = {
        _itself = slot :: Frame,
        _isEmpty = true :: boolean,
        InnerFrame = slot:FindFirstChild("innerFrame", true) :: Frame,
        ImageButton = slot:FindFirstChild("ImageButton", true) :: ImageButton,
        ActionIndicator = slot:FindFirstChild("ActionIndicator", true) :: ImageLabel,
        HotbarNumber = slot:FindFirstChild("HotbarNumber", true) :: TextLabel,
        Quantity = slot:FindFirstChild("Quantity", true) :: TextLabel,
        connections = {},
        tool = nil 
    }
    self.HotbarNumber.Visible = if slotType == "Hotbar" then true else false
    self._itself.Visible = true
    self.ImageButton.Visible = false
    self.ActionIndicator.Visible = false
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
    self.connections.equipAndDragFunctionality = self.ImageButton.MouseButton1Down:Connect(function()
        local selectSlot: RBXScriptConnection?
        local startDrag: RBXScriptConnection?

        selectSlot = self.ImageButton.MouseButton1Up:Once(function()
            print("selecting")
            if selectSlot then
                selectSlot:Disconnect()
                selectSlot = nil
            end
            EquipToolStateMachine.SetTargetTool(self)
        end)
    
        startDrag = UserInputService.InputChanged:Connect(function(inputObject: InputObject, a1: boolean)  
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                if startDrag then
                    startDrag:Disconnect()
                end
                if selectSlot then
                    selectSlot:Disconnect()
                end
            end

            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
            print("dragging")
            Drag.start(self)
            local connection
            connection = UserInputService.InputEnded:Connect(function(inputObject: InputObject, a1: boolean)  
                if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
                    connection:Disconnect()
                    if Hover.currentSlot and Hover.currentSlot ~= self then
                        Slot.SwapSlots(self, Hover.currentSlot)    
                    elseif not Hover.IsInInventory and Hover.currentSlot == nil then
                        bindables.DropToolBindable:Fire(self.tool)
                    else
                        warn("doing nothing with dragged slot")                    
                    end
                    Drag.stop(self)
                end
            end)            
        end
        end)
    end)
    self.connections.kbm_hoverBegin = self._itself.MouseEnter:Connect(function(a0: number, a1: number)  
        Hover.applyEffect(self)
    end) 
    self.connections.kbm_hoverEnd = self._itself.MouseLeave:Connect(function(a0: number, a1: number)  
        Hover.removeEffect(self)
    end)
    table.insert(FilledSlots, self)
end

function Slot.EmptySlot(self : SlotType.SlotType)
    Select.removeEffect(self)
    Hover.removeEffect(self)
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

function Slot.SwapSlots(s1: SlotType.SlotType, s2: SlotType.SlotType)
    if s2._itself.Parent ~= s1._itself.Parent then
        local s2_savedParent = s2._itself.Parent
        s2._itself.LayoutOrder = s1._itself.LayoutOrder
        s1._itself.Parent = s2_savedParent
    end

    local s2LO = s2._itself.LayoutOrder
    local s1LO = s1._itself.LayoutOrder
    s2._itself.LayoutOrder = s1LO
    s2.HotbarNumber.Text = tostring(s1LO)
    s1._itself.LayoutOrder = s2LO
    s1.HotbarNumber.Text = tostring(s2LO)
end

function Slot.destroy(self : SlotType.SlotType)
    self._itself:Destroy()
    for _, v in self.connections do
        v:Disconnect()
    end
    table.clear(self)
end

return Slot