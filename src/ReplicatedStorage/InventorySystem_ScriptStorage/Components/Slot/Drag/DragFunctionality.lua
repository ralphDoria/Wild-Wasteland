local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local Type_Slot = require(ScriptStorage.Components.Slot.Type_Slot)
local Hover = require(ScriptStorage.Components.Slot.Hover)

local dropAreaIndicatorSound: Sound = ReplicatedStorage.InventorySystem_Storage.SFX.dropAreaIndicator
local PlaySound = require(ReplicatedStorage.RojoManaged_RS.Utility.PlaySoundUtil)

local SFX = {
    pickUp = References_Inventory.Storage.SFX.pickUp,
    setDown = References_Inventory.Storage.SFX.setDown,
}

local Drag = {}

Drag.currentSlot = nil
local currentGhostSlots = {}

local function createGhostSlot(slot: Type_Slot.SlotObject)
    local ghostSlot = slot.InnerFrame:Clone()
    ghostSlot:FindFirstChild("HotbarNumber"):Destroy()
    ghostSlot:FindFirstChildOfClass("ImageButton").ImageTransparency = 0
    ghostSlot.Size = UDim2.fromOffset(slot.InnerFrame.AbsoluteSize.X, slot.InnerFrame.AbsoluteSize.X)
    local mousePosInVector2 : Vector2 = References_Inventory.UserInputService:GetMouseLocation()
    ghostSlot.Position = UDim2.fromOffset(mousePosInVector2.X, mousePosInVector2.Y - References_Inventory.GuiService:GetGuiInset().Y)
    ghostSlot.AnchorPoint = Vector2.new(0.5, 0.5)
    ghostSlot.Interactable = false
    ghostSlot.Parent = slot._itself:FindFirstAncestorWhichIsA("ScreenGui")
    return ghostSlot
end

function Drag.start(slot: Type_Slot.SlotObject, whileDragging: () -> ())
    -- slot._itself.Interactable = false
    slot.ImageButton.ImageTransparency = 1
    local ghostSlot = createGhostSlot(slot)
    table.insert(currentGhostSlots, ghostSlot)
    Drag.currentSlot = slot

    References_Inventory.RunService:BindToRenderStep("Drag", 201, function(delta: number)  
        --Positioning drag slot
        local mousePosInVector2 : Vector2 = References_Inventory.UserInputService:GetMouseLocation()
        ghostSlot.Position = ghostSlot.Position:Lerp(UDim2.fromOffset(mousePosInVector2.X, mousePosInVector2.Y - References_Inventory.GuiService:GetGuiInset().Y), 0.3)

        --managing slot action indicators
        if Hover.currentSlot and Hover.currentSlot ~= slot then
            ghostSlot.ActionIndicator.Image = slot.ActionIndicator:GetAttribute("swapImage") :: string
            ghostSlot.ActionIndicator.Visible = true
        elseif Hover.isOutsideInventory() and Hover.currentSlot == nil then
            ghostSlot.ActionIndicator.Image = slot.ActionIndicator:GetAttribute("dropImage") :: string
            if ghostSlot.ActionIndicator.Visible == false then
                ghostSlot.ActionIndicator.Visible = true
                PlaySound(dropAreaIndicatorSound)
            end
        else
            ghostSlot.ActionIndicator.Visible = false                 
        end
        whileDragging()
    end)
end

function Drag.stop(slot: Type_Slot.SlotObject)
    -- slot._itself.Interactable = true
    slot.ImageButton.ImageTransparency = 0
    References_Inventory.RunService:UnbindFromRenderStep("Drag")
    for _, v in currentGhostSlots do
        v:Destroy()
    end
    Drag.currentSlot = nil
end

function Drag.InitForSlot(slot: Type_Slot.SlotObject, onDragStarted: () -> (), onDragStopped: (hoverSlot: Type_Slot.SlotObject?, isOutsideInventory: boolean) -> ()): RBXScriptConnection
    return slot.ImageButton.MouseButton1Down:Connect(function()

        -- reason for these cached variables is because on touch inputs, hover coincides w/ drag via long presss
        local cached: {hoverSlot: Type_Slot.SlotObject?, isOutsideInventory: boolean} = {
            hoverSlot = nil,
            isOutsideInventory = false
        }

        local startDrag: RBXScriptConnection
        startDrag = References_Inventory.UserInputService.InputChanged:Connect(function(inputObject: InputObject, a1: boolean)  
            if inputObject.UserInputType == Enum.UserInputType.MouseMovement
                or inputObject.UserInputType == Enum.UserInputType.Touch then
                startDrag:Disconnect()
                if References_Inventory.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    Drag.start(slot, function()
                        cached.hoverSlot = Hover.currentSlot
                        cached.isOutsideInventory = Hover.isOutsideInventory()
                    end)
                    onDragStarted()                    
                    PlaySound(SFX.pickUp)
                end
            end
        end)

        local endDrag
        endDrag = References_Inventory.UserInputService.InputEnded:Connect(function(inputObject: InputObject, a1: boolean)  

            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then

                if Drag.currentSlot == nil then
                    endDrag:Disconnect()
                    startDrag:Disconnect()
                    print("Cancelling drag functionality")
                    return
                end

                endDrag:Disconnect()
                Drag.stop(slot)
                PlaySound(SFX.setDown)

                onDragStopped(cached.hoverSlot, cached.isOutsideInventory)
            end
        end)
    end)
end

return Drag