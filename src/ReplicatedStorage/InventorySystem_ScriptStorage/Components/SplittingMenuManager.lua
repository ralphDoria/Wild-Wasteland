local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local Hover = require(InventoryScriptStorage.Components.Slot.Hover)
local UiSliderManager = require(RS.RojoManaged_RS.Utility.UiSliderManager)
local Type_Slot = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Type_Slot)

local Trove = require(RS.Packages.Trove)
local Promise = require(RS.Packages.Promise)

local stackableRemotes = RS.ItemSystem_Storage.Stackable.Remotes
local remotes = {
    RequestDuplicateStackable = stackableRemotes.RequestDuplicateStackable:: RemoteFunction,
    RequestQuantityTransfer = stackableRemotes.RequestQuantityTransfer:: RemoteFunction,
    -- DestroyUnusedStackable = stackableRemotes.DestroyUnusedStackable:: RemoteEvent,
    CancelDuplicateRequest = stackableRemotes.CancelDuplicateRequest:: RemoteEvent,
}

export type SplitSlotMenuObject = {
    splitSlot: Type_Slot.SlotObject?,
    duplicateStackable: Tool?,
    trove: any,
    cleanUp: () -> ()?,
    operationId: number,
}

export type SplittingMenuManager = {
    SplittingMenuFrame: Frame,
    Slider: Frame,
    Bar: TextButton,
    Fill: Frame,
    ValueBox: TextBox,
    SliderNumberValue: NumberValue,
    sliderObject: UiSliderManager.UiSliderObject,
    loadingIcon: ImageLabel,
    splittingLabel: TextLabel,

    splitSlotMenuObject: SplitSlotMenuObject?,
    currentOperation_createSplitSlotMenu: any,
    internalValuechanged: RBXScriptSignal,
}
local currentOperationId = 0 -- per client

local SplittingMenuManager = {}

local ti = TweenInfo.new(0.1)
local openSize = UDim2.fromScale(0.25, 0.25)
local closeSize = UDim2.fromScale(0.25, 0)

local makeChildrenInvisible: RBXScriptConnection

function SplittingMenuManager.new(SplittingMenuFrame: Frame)
    -- Slider  
    local Slider = SplittingMenuFrame:WaitForChild("Slider"):: Frame
    local Bar = Slider:WaitForChild("Bar"):: TextButton
    local Fill = Bar:WaitForChild("Fill"):: Frame
    local ValueBox = Slider:WaitForChild("ValueBox"):: TextBox
    local loadingIcon = SplittingMenuFrame:WaitForChild("LoadingIconHolder"):WaitForChild("LoadingIcon"):: ImageLabel
    local splittingLabel = SplittingMenuFrame:WaitForChild("SplittingLabel"):: TextLabel
    local SliderNumberValue = Slider:WaitForChild("SliderNumberValue"):: NumberValue
    local sliderObject = UiSliderManager.new(ValueBox, Bar, Fill)

    local self: SplittingMenuManager = {
        SplittingMenuFrame = SplittingMenuFrame,
        Slider = Slider,
        Bar = Bar,
        Fill = Fill,
        ValueBox = ValueBox,
        SliderNumberValue = SliderNumberValue,
        sliderObject = sliderObject,
        loadingIcon = loadingIcon,
        splittingLabel = splittingLabel,

        splitSlotMenuObject = nil,
        currentOperation_createSplitSlotMenu = nil,
        internalValuechanged = sliderObject.internalValueChanged,
    }

    return self
end

function SplittingMenuManager.createAndShowSplitSlotMenu(self: SplittingMenuManager, stackableTool: Tool, onClosed, newSlot, fillSlot, suspendSlot, stateChanged: RBXScriptSignal)

    if self.currentOperation_createSplitSlotMenu then
        self.currentOperation_createSplitSlotMenu:cancel() 
    end
    if self.splitSlotMenuObject and self.splitSlotMenuObject.cleanUp then
        self.splitSlotMenuObject.cleanUp()
    end

    currentOperationId += 1
    local splitSlotMenu: SplitSlotMenuObject = {
        splitSlot = nil,
        trove = Trove.new(),
        cleanUp = nil,
        operationId = currentOperationId
    }
    self.splitSlotMenuObject = splitSlotMenu

    self.currentOperation_createSplitSlotMenu = Promise.new(function(resolve, reject, onCancel)
        SplittingMenuManager._toggleLoadingIcon(self, true)
        SplittingMenuManager.toggleShow(self, true)
        local onCloseAreaClicked: RBXScriptConnection

        splitSlotMenu.cleanUp = function()
            if onCloseAreaClicked then
                onCloseAreaClicked:Disconnect()
            end
            splitSlotMenu.trove:Destroy()
            SplittingMenuManager.toggleShow(self, false)
            if splitSlotMenu.splitSlot then
                splitSlotMenu.splitSlot._itself:Destroy()
                if splitSlotMenu.splitSlot._itself:GetAttribute("Used") == nil then
                    local duplicateStackable = splitSlotMenu.duplicateStackable
                    if duplicateStackable then
                        task.spawn(function()
                            remotes.RequestQuantityTransfer:InvokeServer(stackableTool, duplicateStackable, 0)
                        end)
                        remotes.CancelDuplicateRequest:FireServer(splitSlotMenu.operationId)
                    end
                end
            end
            table.clear(splitSlotMenu)
            onClosed()
            -- print("CleanUp SplitSlotMenu Completed")
        end
        
        onCloseAreaClicked = SplittingMenuManager.connectOnCloseAreaClicked(function()  
            if splitSlotMenu.cleanUp then
                splitSlotMenu.cleanUp()
            end
        end)

        onCancel(function()
            if splitSlotMenu.cleanUp then
                splitSlotMenu.cleanUp()
            end
        end)
        
        local duplicateStackable: Tool? = remotes.RequestDuplicateStackable:InvokeServer(splitSlotMenu.operationId, stackableTool)
        if duplicateStackable then
            duplicateStackable:AddTag("IgnoreInventorySlotAutofill")
            splitSlotMenu.duplicateStackable = duplicateStackable
            resolve(duplicateStackable)
        else
            reject("Failed to get duplicate stackable")
        end
    end)
        :andThen(function(duplicateStackable: Tool)
            SplittingMenuManager._toggleLoadingIcon(self, false)
            local splitSlot = newSlot("Inventory"):: Type_Slot.SlotObject
            splitSlot._itself:AddTag("SplitSlot")
            fillSlot(splitSlot, duplicateStackable)
            suspendSlot(splitSlot, true)
            UiSliderManager.setSliderRange(self.sliderObject, 1, stackableTool:GetAttribute("Quantity"):: number - 1)
            UiSliderManager.forceToZero(self.sliderObject)
            splitSlot._itself.LayoutOrder = 2
            splitSlot._itself.Parent = self.SplittingMenuFrame

            splitSlotMenu.trove:Connect(self.sliderObject.internalValueChanged, function(internalValue: number)
                suspendSlot(splitSlot, true)
                remotes.RequestQuantityTransfer:InvokeServer(stackableTool, duplicateStackable, internalValue)
                suspendSlot(splitSlot, false)
            end)

            print("Connecting slot state changed")
            local lastState
            splitSlotMenu.trove:Connect(stateChanged, function(slot, state)  
                if slot.tool and slot.tool == duplicateStackable then
                    if state == "Dragging" then
                        SplittingMenuManager.toggleShow(self, false) 
                    elseif state == "Idle" and lastState == "Dragging" then
                        if splitSlot._itself:GetAttribute("Merging") then return end
                        SplittingMenuManager.toggleShow(self, true) 
                    end
                    lastState = state
                end
            end)

            splitSlotMenu.trove:Connect(splitSlot._itself:GetAttributeChangedSignal("Used"), function()
                local slotInstance = splitSlot._itself
                if slotInstance:GetAttribute("Used") == true then
                    if splitSlotMenu.cleanUp then
                        splitSlotMenu.cleanUp()
                    end
                end
            end)

            splitSlotMenu.trove:Connect(splitSlot._itself:GetAttributeChangedSignal("UpdateSplittingMenuMaxQuantity"), function()
                local slotInstance = splitSlot._itself
                if slotInstance:GetAttribute("UpdateSplittingMenuMaxQuantity") == true then
                    local newTotal = stackableTool:GetAttribute("Quantity"):: number + duplicateStackable:GetAttribute("Quantity"):: number
                    if newTotal < 2 then
                        if splitSlotMenu.cleanUp then
                            splitSlotMenu.cleanUp()
                        end
                    else
                        UiSliderManager.setSliderRange(self.sliderObject, 1, newTotal - 1)
                        UiSliderManager.forceToZero(self.sliderObject)
                        SplittingMenuManager.toggleShow(self, true)
                    end
                    slotInstance:SetAttribute("UpdateSplittingMenuMaxQuantity", nil)
                end
            end)

            splitSlotMenu.splitSlot = splitSlot
           return 
        end)
        :catch(function(err)
            SplittingMenuManager._toggleLoadingIcon(self, false)
            warn(tostring(err))
        end)
end

function SplittingMenuManager.toggleShow(self: SplittingMenuManager, toggle: boolean)
    local SplittingMenuFrame = self.SplittingMenuFrame
    if toggle then
        SplittingMenuFrame.Visible = true
        self.sliderObject.textBox:CaptureFocus()
    else
        self.sliderObject.textBox:ReleaseFocus()
    end
    local tween = TweenService:Create(SplittingMenuFrame, ti, {Size = if toggle then openSize else closeSize})
    tween.Completed:Once(function()  
        if SplittingMenuFrame.Size == closeSize then
            SplittingMenuFrame.Visible = false
        end

    end)
    tween:Play()
end

function SplittingMenuManager._toggleLoadingIcon(self: SplittingMenuManager, toggle: boolean)
    if toggle then
        self.loadingIcon.Rotation = -180
        self.loadingIcon.Visible = true
        TweenService:Create(self.loadingIcon, TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.In, math.huge), {Rotation = 180}):Play()

        self.splittingLabel.Visible = false
        self.Slider.Visible = false
        self.ValueBox.Visible = false
        if makeChildrenInvisible then
            makeChildrenInvisible:Disconnect()
        end
        makeChildrenInvisible = self.SplittingMenuFrame.ChildAdded:Connect(function(child: Instance)  
            if child:IsA("Frame") then
                print("making this thang invisible")
                child.Visible = false
            end
        end)
    else
        TweenService:Create(self.loadingIcon, TweenInfo.new(0), {Rotation = 0}):Play()
        self.loadingIcon.Visible = false

        self.splittingLabel.Visible = true
        self.Slider.Visible = true
        self.ValueBox.Visible = true
        if makeChildrenInvisible then
            makeChildrenInvisible:Disconnect()
        else
            print("makingChildrenInvisible connection not found")
        end
        for _, v in self.SplittingMenuFrame:GetChildren() do
            if v:IsA("GuiBase2d") and v.Visible == false then
                v.Visible = true
            end
        end
    end
end

function SplittingMenuManager.connectOnCloseAreaClicked(callback: () -> ()): RBXScriptConnection
    local function _inputAndAreaChecks(inputObject: InputObject)
        return (inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch) and Hover.isOutsideSplittingMenu()
    end

    return UserInputService.InputBegan:Connect(function(io1: InputObject)  
        if _inputAndAreaChecks(io1) then
                callback()
        end
    end)
end

function SplittingMenuManager.Destroy(self: SplittingMenuManager)
    UiSliderManager.Destroy(self.sliderObject)
end

return SplittingMenuManager
