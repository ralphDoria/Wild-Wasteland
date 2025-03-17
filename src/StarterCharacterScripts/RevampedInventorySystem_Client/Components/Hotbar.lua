local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bindables : {[string] : BindableEvent} = {
    toggleEquip = ReplicatedStorage.ToolSystem_Storage.Shared:FindFirstChild("toggleEquip", true)
}

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
local hotbarNumberToSlot : {Slot.SlotType} = {}

local HotbarManager = {}

function HotbarManager.init(SlotTemplate : Frame, hotbar : CanvasGroup)
    Hotbar = hotbar
    for i, _ in hotbarNumberToKeybind do
		local slot = SlotTemplate:Clone()
		slot.Parent = hotbar
		hotbarNumberToSlot[i] = Slot.new(slot, "Hotbar")
		hotbarNumberToSlot[i].HotbarNumber.Text = tostring(i)
	end
    HotbarManager.toggleKeybindToHotbarSlot(true)
end

function HotbarManager.findMinimumEmptyHotbarSlot() : Slot.SlotType?
    for _, v in hotbarNumberToSlot do
        if v._isEmpty == true then
            return v
        end
    end

    return nil
end

local keybindConnection : RBXScriptConnection?
function HotbarManager.toggleKeybindToHotbarSlot(toggle : boolean)
    if toggle then
        --warn("enbaling keybindToHotbarSlot")
        keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            local slotIndex = table.find(hotbarNumberToKeybind, input.KeyCode)
            if slotIndex then
                local associatedHotbarSlot : Slot.SlotType= hotbarNumberToSlot[slotIndex]
                if not associatedHotbarSlot._isEmpty then
                    Bindables.toggleEquip:Fire(associatedHotbarSlot.tool)
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