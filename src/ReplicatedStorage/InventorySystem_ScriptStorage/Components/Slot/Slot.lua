--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local PlaySound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

local ItemSystem_Storage = References_Inventory.ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local bindables = {
    DropToolBindable = ItemSystem_Storage.Shared.Bindables.DropToolBindable,
    ToggleDropBind = ItemSystem_Storage.Shared.Bindables.ToggleDropBind
}

local SFX = {
    hover = References_Inventory.Storage.SFX.hover
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local Type_Slot = require("./../Slot/Type_Slot")
local Type_Equipment = require("./../../CharacterSection/Components/Type_Equipment")
local EquipmentInitData = require("./../../CharacterSection/Components/EquipmentInitData")
local Hover = require("./../Slot/Hover")
local Select = require("./../Slot/Select")
local DragFunctionality = require("./../Slot/Drag/DragFunctionality")
local ToolStateMachine = require("./../ToolStateMachine/Main_ToolStateMachine")
local handleDragDrop = require(InventoryScriptStorage.Components.Slot.Drag.handleDragDrop)
local SlotRegistry = require(InventoryScriptStorage.Components.Slot.SlotRegistry)
local SplittingMenuManager = require(InventoryScriptStorage.Components.SplittingMenuManager)

export type SlotObject = Type_Slot.SlotObject
export type State = Type_Slot.SlotState
local Slot = {}
Slot.instanceToObjectMap = SlotRegistry.instanceToObjectMap
Slot.toolToObjectMap = SlotRegistry.toolToObjectMap
Slot.wearableCategoryToObjectMap = SlotRegistry.wearableCategoryToObjectMap

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
    local slotInstance = References_Inventory.TemplateSlot:Clone()

    local self : Type_Slot.SlotObject = {
        State = "Idle",
        _itself = slotInstance :: Frame,
        _isEmpty = true :: boolean,
        InnerFrame = slotInstance:FindFirstChild("innerFrame", true) :: Frame,
        ImageButton = slotInstance:FindFirstChild("ImageButton", true) :: ImageButton,
        ActionIndicator = slotInstance:FindFirstChild("ActionIndicator", true) :: ImageLabel,
        HotbarNumber = slotInstance:FindFirstChild("HotbarNumber", true) :: TextLabel,
        FilledSlotCounter = slotInstance:FindFirstChild("FilledSlotCounter", true) :: TextLabel,
        Quantity = slotInstance:FindFirstChild("Quantity", true) :: TextLabel,
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
        if DragFunctionality.currentSlot then
            PlaySound(SFX.hover)
        end
    end) 
    self.connections.hoverEnd = self._itself.MouseLeave:Connect(function(a0: number, a1: number)  
        Hover.removeEffect(self)
    end)
    self.connections.onDestroying = self._itself.Destroying:Connect(function(...: any)  
        print(`Destroying slot that contains {self.tool}`)
        Slot.destroy(self)
    end)

    Slot.instanceToObjectMap[slotInstance] = self

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

local TweenService = References_Inventory.TweenService
function Slot.loadSlot(slot: SlotObject, duration: number)
    local progressBar = Instance.new("Frame")
    progressBar.Transparency = 0.5
    progressBar.Size = UDim2.fromScale(1, 1)
    progressBar.Parent = slot._itself
    local tween = TweenService:Create(progressBar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {Size = UDim2.fromScale(0, 1)})
    tween.Completed:Connect(function()  
        progressBar:Destroy()
    end)
    return tween
end

function Slot.toggleSuspend(slot: SlotObject, toggle: boolean)
    if toggle then
        slot.ActionIndicator.Image = slot.ActionIndicator:GetAttribute("suspendImage"):: string
        slot.ActionIndicator.Rotation = -180
        slot.ActionIndicator.Visible = true
        TweenService:Create(slot.ActionIndicator, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge), {Rotation = 180}):Play()
        slot.ImageButton.Interactable = false
        Slot.ChangeState(slot, "Suspended")
    else
        TweenService:Create(slot.ActionIndicator, TweenInfo.new(0), {Rotation = 0}):Play()
        slot.ActionIndicator.Visible = false
        slot.ImageButton.Interactable = true
        Slot.ChangeState(slot, "Idle")
    end
end

function Slot.FillSlot(self : Type_Slot.SlotObject, tool : Tool)
    Slot.ChangeState(self, "Filling")
    -- print("Filling slot: ", self.HotbarNumber.Text)
    self.ImageButton.Image = tool.TextureId
    self.tool = tool
    self.ImageButton.Visible = true

    local quantityValue = tool:GetAttribute("Quantity")
    if quantityValue then
        self.Quantity.Text = "x" .. tostring(quantityValue)
        self.Quantity.Visible = true
        self.connections.updateQuantityLabel = tool:GetAttributeChangedSignal("Quantity"):Connect(function()  
            self.Quantity.Text = "x" .. tostring(tool:GetAttribute("Quantity"))
        end) 

        self.connections.openSplittingMenu = self.ImageButton.MouseButton2Click:Connect(function()  
            -- initialize split slot
            if self._itself:HasTag("SplitSlot") or self.tool and self.tool:GetAttribute("Quantity") < 2 then return end

            bindables.ToggleDropBind:Fire(self.tool, false)
            Slot.toggleSuspend(self, true) -- have to suspend slot to prevent player from potentially dropping it before quantity has time to adjust (quantity can only be adjusted if in player's inventory)
            SplittingMenuManager.createAndShowSplitSlotMenu(References_Inventory.splittingMenuObject, tool, 
                function() -- onClosed()
                    if self.tool and self.tool:GetAttribute("State") == "Idle" then
                        bindables.ToggleDropBind:Fire(self.tool, true)
                    end
                    Slot.toggleSuspend(self, false)
                end, 
                Slot.new, Slot.FillSlot, Slot.toggleSuspend, Slot.StateChanged)
        end)
        --for mobile players, I'm thinking a long touch is how they'll open the splitting menu
    end
    self._isEmpty = false

    if not self.WearableCategory and self._itself.Parent ~= References_Inventory.LootingEquipmentSlots 
        and self._itself.Parent and self._itself.Parent.Parent ~= References_Inventory.LootingScrollingFrame  then
        self.connections.EquipFromClick = self.ImageButton.MouseButton1Click:Connect(function(...: any) 
            assert(self.tool ~= nil)
            local state = self.tool:GetAttribute("State")
            if state == "Unequipping" or state == "Unequipped" then
                ToolStateMachine.SetTargets(self, "Idle")
            elseif state == "Equipping" or state == "Idle" then
                ToolStateMachine.SetTargets(self, "Unequipped")
            end
        end)
    end

    local FilledSlotCounter = self.FilledSlotCounter
    local function updateFilledSlotsAndIsEmptyStatus(slotGroupInstance: Frame)
        local numberOfFilledSlots = slotGroupInstance:GetAttribute("FilledSlotCounter_Client"):: string
        FilledSlotCounter.Text = numberOfFilledSlots
        local num = tonumber(numberOfFilledSlots:sub(1, 1))
        if self.tool then
            self.tool:SetAttribute("isEmpty_client", num == 0)
        end
    end

    if self.WearableCategory and tool:HasTag("StorageWearable") then

        local associatedSlotGroup: ObjectValue? = tool:FindFirstChild("AssociatedItemGroup"):: ObjectValue?
        if associatedSlotGroup then
            warn("slot group found")
            local  connection
            
            print(`connecting associatedSlotGroup value property changed event listener, current associatedSlotGroup.Value = {associatedSlotGroup.Value}`)
            self.connections.onNewSlotGroupInstanceAdded = associatedSlotGroup:GetPropertyChangedSignal("Value"):Connect(function()  
                print("running callback")
                if connection then
                    connection:Disconnect()
                end
                local slotGroupInstance = associatedSlotGroup.Value:: Frame
                if slotGroupInstance then

                    updateFilledSlotsAndIsEmptyStatus(slotGroupInstance)
                    print("slotGroupInstance found, making FilledSlotcounter visible")
                    FilledSlotCounter.Visible = true

                    connection = slotGroupInstance:GetAttributeChangedSignal("FilledSlotCounter_Client"):Connect(function()
                        updateFilledSlotsAndIsEmptyStatus(slotGroupInstance)
                    end)

                    
                else
                    print("slotGroupInstance not found")
                    if connection then
                        connection:Disconnect()
                    end
                end
            end)
        else
            warn("ASSOCIATED SLOT GROUP NOT FOUND")
        end
    end

    self.connections.DragFunctionality = DragFunctionality.InitForSlot(self, 
        function()
            Slot.ChangeState(self, "Dragging")
        end,
        function(hoverSlot, isOutsideInventory)
            Slot.ChangeState(self, "Idle")
            handleDragDrop(self, isOutsideInventory, hoverSlot, Slot.ChangeState, Slot.FillSlot, Slot.EmptySlot, Slot.new, Slot.destroy)
        end
    )

    Slot.toolToObjectMap[tool] = self

    Slot.ChangeState(self, "Idle")
end

function Slot.EmptySlot(self : Type_Slot.SlotObject?)
    if self == nil then 
        warn("Cannot empty slot, SlotObject is nil")
        -- print(debug.traceback())
        return 
    end

    Slot.toolToObjectMap[self.tool:: Tool] = nil

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

    if self.WearableCategory then
        self.ImageButton.Visible = true
        self.ImageButton.Image = EquipmentInitData[self.WearableCategory].image
    end
    Slot.ChangeState(self, "Idle")
end

function Slot.destroy(self : Type_Slot.SlotObject)
    Slot.ChangeState(self, "Destroying")

    local slotInstance = self._itself
    if slotInstance then
        Slot.instanceToObjectMap[self._itself] = nil  
    end

    local tool = self.tool
    if tool then
        Slot.toolToObjectMap[tool] = nil    
    end

    if self._itself.Parent ~= nil then
        self._itself:Destroy()    
    end
    for _, v in self.connections do
        v:Disconnect()
    end
    table.clear(self)
end

return Slot