--!strict

local playerGui : PlayerGui = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerGui") :: PlayerGui
local gui : ScreenGui = playerGui:WaitForChild("RevampingInventory") :: ScreenGui
local Templates : Folder = gui:FindFirstChild("Templates") :: Folder
local SlotTemplate : Frame = Templates:FindFirstChild("SlotTemplate") :: Frame
local InventoryState = require("./../InventoryState")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventorySystem_Storage = ReplicatedStorage:FindFirstChild("InventorySystem_Storage", true)
local SFX: {pickUp: Sound, hover: Sound, setDown: Sound} = {
    pickUp = InventorySystem_Storage.SFX.pickUp,
    hover = InventorySystem_Storage.SFX.hover,
    setDown = InventorySystem_Storage.SFX.setDown,
}
local PlaySound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

local SlotType = require("./../SlotType")
local WearableCategory = require("./../WearableCategory")
local WearableSlotInfo = require("./../WearableSlotInfo")
local FilledSlotsTracker = require("./FilledSlotsTracker")
-- local WearItemStateMachine = require("./WearItemStateMachine")
export type SlotType = SlotType.SlotType
local Hover = require("./../Hover")
local Select = require("./../Select")
local Config = require("./../Config")
local UserInputService = game:GetService("UserInputService")
local Drag = require("./../Drag")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}

local ToolStateMachine = require("./../ToolStateMachine/Main")

local Slot = {}

local isDragging: boolean = false

local SlotStateChangedBindable: BindableEvent = Instance.new("BindableEvent")
Slot.StateChanged = SlotStateChangedBindable.Event

-- Slot.StateChanged:Connect(function(thisSlot: SlotType)  
--     if thisSlot.State == "BeingSwapped" then
--         print("BeingSwapped")
--     end
-- end)

----    Local Functions

----    Methods

function Slot.new(slotType : "Hotbar" | "Inventory" | "Wearable", wearableCategory: WearableCategory.WearableCategoryType?) : SlotType.SlotType
    local slot = SlotTemplate:Clone()

    local self : SlotType.SlotType = {
        State = "Idle",
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
        if isDragging then
            PlaySound(SFX.hover)
        end
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
    if self.State ~= state then
        self.State = state
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
            assert(self.tool ~= nil)
            local state = self.tool:GetAttribute("State")
            warn("Checkpoint 1", state)
            if state == "Unequipping" or state == "Unequipped" then
                warn("Checkpoint 2a")
                ToolStateMachine.SetTargets(self, "Idle")
            elseif state == "Equipping" or state == "Idle" then
                warn("Checkpoint 2b")
                ToolStateMachine.SetTargets(self, "Unequipped")
            end
        end)
    end

    self.connections.DragFunctionality = self.ImageButton.MouseButton1Down:Connect(function()
        local startDrag: RBXScriptConnection
        local cachedHoverSlot
        startDrag = UserInputService.InputChanged:Connect(function(inputObject: InputObject, a1: boolean)  
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement
                or inputObject.UserInputType == Enum.UserInputType.Touch then
                startDrag:Disconnect()
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    Drag.start(self, function()
                        cachedHoverSlot = Hover.currentSlot
                    end)
                    PlaySound(SFX.pickUp)
                    isDragging = true
                end
            end
        end)

        local endDrag
        endDrag = UserInputService.InputEnded:Connect(function(inputObject: InputObject, a1: boolean)  


            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then

                if not isDragging then
                    endDrag:Disconnect()
                    startDrag:Disconnect()
                    print("Cancelling drag functionality")
                    return
                end

                endDrag:Disconnect()
                isDragging = false
                -- reason for these cahced variables is because on touch inputs, hover coincides w/ drag via long presss
                Drag.stop(self)
                PlaySound(SFX.setDown)
                isDragging = false
                if cachedHoverSlot and cachedHoverSlot ~= self then
                    Slot.SwapSlots(self, cachedHoverSlot)
                elseif Hover.InDropArea and cachedHoverSlot == nil then
                    if self.State ~= "BeingSwapped" then
                        bindables.DropToolBindable:Fire(self.tool)
                    end
                else
                    warn("doing nothing with dragged slot")                    
                end
            end
        end)
    end)
    table.insert(FilledSlotsTracker.FilledSlots, self)
    Slot.ChangeState(self, "Idle")
end

local TweenService = game:GetService("TweenService")
function Slot.load(self: SlotType.SlotType, duration: number)
    local progressBar = Instance.new("Frame")
    progressBar.Transparency = 0.5
    progressBar.Size = UDim2.fromScale(1, 1)
    progressBar.Parent = self._itself
    local tween = TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)})
    tween.Completed:Connect(function()  
        progressBar:Destroy()
    end)
    return tween
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
    table.remove(FilledSlotsTracker.FilledSlots, table.find(FilledSlotsTracker.FilledSlots, self))

    if self.WearableCategory then
        self.ImageButton.Visible = true
        self.ImageButton.Image = WearableSlotInfo[self.WearableCategory].image
    end
    Slot.ChangeState(self, "Idle")
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
        if wearableSlot.tool and itemSlot.tool then -- both are filled
            if itemSlot.tool:GetAttribute("WearableCategory") ~= wearableSlot.tool:GetAttribute("WearableCategory") then return end 

            local tweens: {Tween} = {}
            ToolStateMachine.SetTargets(itemSlot, "Worn", 
                function(estimatedPathsTime: number) -- onValidated
                    Slot.ChangeState(wearableSlot, "BeingSwapped")
                    Slot.ChangeState(itemSlot, "BeingSwapped")
                    InventoryState.ChangeState("SwappingSlots")

                    table.insert(tweens, Slot.load(wearableSlot, estimatedPathsTime))
                    table.insert(tweens, Slot.load(itemSlot, estimatedPathsTime))
                    for _, v in tweens do
                        v:Play()
                    end
                end,
                function(status: string) --onFinished

                    Slot.ChangeState(wearableSlot, "Idle")
                    Slot.ChangeState(itemSlot, "Idle")
                    InventoryState.ChangeState("Idle")

                    if status == "Resolved" then
                        local wearableSlotTool = wearableSlot.tool
                        Slot.EmptySlot(wearableSlot)
                        Slot.FillSlot(wearableSlot, itemSlot.tool, "")
                        Slot.EmptySlot(itemSlot)
                        Slot.FillSlot(itemSlot, wearableSlotTool, "")
                    elseif status == "Cancelled" then
                        for _, v in tweens do
                            if v.PlaybackState == Enum.PlaybackState.Playing then
                                v:Cancel()                        
                            end
                        end
                        warn("Cancelled")
                    else
                        warn(`Something went wrong involving {itemSlot.tool}; Promise State: {status}`)
                    end
                end
            )

        elseif wearableSlot.tool == nil and itemSlot.tool == nil then -- both are empty
            -- do fucking nothing
        elseif wearableSlot.tool == nil then -- wearable slot is empty, item slot is filled
            if itemSlot.tool:GetAttribute("WearableCategory") ~= wearableSlot.WearableCategory then return end
            

            local tweens: {Tween} = {}
            ToolStateMachine.SetTargets(itemSlot, "Worn", 
                function(timeUntilComplete: number) -- onValidated
                    Slot.ChangeState(wearableSlot, "BeingSwapped")
                    Slot.ChangeState(itemSlot, "BeingSwapped")
                    InventoryState.ChangeState("SwappingSlots")

                    table.insert(tweens, Slot.load(wearableSlot, timeUntilComplete))
                    table.insert(tweens, Slot.load(itemSlot, timeUntilComplete))
                    for _, v in tweens do
                        v:Play()
                    end
                end,
                function(status: string)  
                    if status == "Resolved" then
                        Slot.FillSlot(wearableSlot, itemSlot.tool, "")
                        Slot.EmptySlot(itemSlot)
                    elseif status == "Never Ran" then
                        warn("Can't wear item, various possible reasons: current tool is in some activated state, item to swap with is not compatible")
                    elseif status == "Cancelled" then
                        for _, v in tweens do
                            if v.PlaybackState == Enum.PlaybackState.Playing then
                                v:Cancel()                        
                            end
                        end
                        warn("Cancelled")
                    end
                    if status == "Resolved" or status == "Never Ran" then
                        Slot.ChangeState(wearableSlot, "Idle")
                        Slot.ChangeState(itemSlot, "Idle")
                        InventoryState.ChangeState("Idle")
                    end
                end
            )

        else -- itemSlot.tool == nil; wearable slot is filled, item slot is empty
            local tweens: {Tween} = {}
            ToolStateMachine.SetTargets(wearableSlot, "Unequipped", 
                function(timeUntilComplete: number)
                    table.insert(tweens, Slot.load(wearableSlot, timeUntilComplete))
                    table.insert(tweens, Slot.load(itemSlot, timeUntilComplete))
                    for _, v in tweens do
                        v:Play()
                    end

                    Slot.ChangeState(wearableSlot, "BeingSwapped")
                    Slot.ChangeState(itemSlot, "BeingSwapped")
                    InventoryState.ChangeState("SwappingSlots")
                end,
                function(status: string)  
                    if status == "Resolved" then
                        Slot.FillSlot(itemSlot, wearableSlot.tool, "")
                        Slot.EmptySlot(wearableSlot)
                    elseif status == "Never Ran" then
                        warn("Can't wear item, various possible reasons: current tool is in some activated state, item to swap with is not compatible")
                    elseif status == "Cancelled" then
                        for _, v in tweens do
                            if v.PlaybackState == Enum.PlaybackState.Playing then
                                v:Cancel()                        
                            end
                        end
                        warn("Cancelled")
                    end
                    if status == "Resolved" or status == "Never Ran" then
                        Slot.ChangeState(wearableSlot, "Idle")
                        Slot.ChangeState(itemSlot, "Idle")
                        InventoryState.ChangeState("Idle")
                    end
                end
            )
        end
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