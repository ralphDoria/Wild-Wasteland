--!strict
local EquipToolStateMachine = require("./EquipToolStateMachine")

local Slot = require("./Slot")
local UserInputService = game:GetService("UserInputService")

local Hotbar : CanvasGroup? = nil

local hotbarNumberToKeybind = {
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five
}
local hotbarSlotToSlotData : {[Frame]: Slot.SlotType} = {}

local HotbarManager = {}

function HotbarManager.init(SlotTemplate : Frame, hotbar : CanvasGroup)
    Hotbar = hotbar
    for i, _ in hotbarNumberToKeybind do
		local slot = SlotTemplate:Clone()
		slot.Parent = hotbar
		hotbarSlotToSlotData[slot] = Slot.new(slot, "Hotbar")
		hotbarSlotToSlotData[slot].HotbarNumber.Text = tostring(i)
        hotbarSlotToSlotData[slot]._itself.LayoutOrder = i
	end
    HotbarManager.toggleKeybindToHotbarSlot(true)
end

function HotbarManager.findMinimumEmptyHotbarSlot() : Slot.SlotType?
    local lowest: Slot.SlotType? = nil
    for _, v in hotbarSlotToSlotData do
        if v._isEmpty == true then
            if lowest == nil then
                lowest = v
            else
                if v._itself.LayoutOrder < lowest._itself.LayoutOrder then
                    lowest = v
                end
            end
        end
    end

    return lowest
end

local keybindConnection : RBXScriptConnection?
function HotbarManager.toggleKeybindToHotbarSlot(toggle : boolean)
    if toggle then
        --warn("enbaling keybindToHotbarSlot")
        keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if Hotbar then
                for _, v in Hotbar:GetChildren() do
                    if v:IsA("Frame") then
                        if v.LayoutOrder == table.find(hotbarNumberToKeybind, input.KeyCode) then
                            local correspondingHotbarSlot = hotbarSlotToSlotData[v]
                            if correspondingHotbarSlot._isEmpty == false then
                                EquipToolStateMachine.SetTargetTool(correspondingHotbarSlot)
                            end
                        end
                    end
                end
            end
        end)
        if Hotbar ~= nil then
            if Hotbar.GroupTransparency > 0 then
                HotbarManager.GroupTransparency = 0
            end
        else
            error("Need to initialize hotbar first before calling this function")
        end
    else
        --warn("disabling keybindToHotbarSlot")
		if keybindConnection ~= nil then
			keybindConnection:Disconnect()
		end
        keybindConnection = nil
        HotbarManager.GroupTransparency = 0.5
    end
end

return HotbarManager