--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolStateMachine = require("./../Components/ToolStateMachine/Main_ToolStateMachine")
local Slot = require("./../Components/Slot/Slot")
local UserInputService = game:GetService("UserInputService")
local HotbarSlotsRegistry = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.HotbarSection.Components.HotbarSlotsRegistry)
local Trove = require(ReplicatedStorage.Packages.Trove)

local hotbarNumberToKeybind = {
	[1] = Enum.KeyCode.One,
	[2] = Enum.KeyCode.Two,
	[3] = Enum.KeyCode.Three,
	[4] = Enum.KeyCode.Four,
	[5] = Enum.KeyCode.Five
}
local hotbarSlotToSlotData : {[Frame]: Slot.SlotObject} = HotbarSlotsRegistry.instanceToObjectMap

export type HotbarObject = {
    hotbar: CanvasGroup,
    keybindConnection: RBXScriptConnection?,
    trove: any
}

local HotbarManager = {}
HotbarManager.Connections = {}

function HotbarManager.new(hotbar : CanvasGroup): HotbarObject
    local self: HotbarObject = {
        hotbar = hotbar,
        keybindConnection = nil,
        trove = Trove.new()
    }
    

    for i, _ in hotbarNumberToKeybind do
        local slot = Slot.new("Hotbar")
        slot._itself.Parent = hotbar
		hotbarSlotToSlotData[slot._itself] = slot
		hotbarSlotToSlotData[slot._itself].HotbarNumber.Text = tostring(i)
        hotbarSlotToSlotData[slot._itself]._itself.LayoutOrder = i
        slot._itself.Destroying:Once(function(...: any)  
            hotbarSlotToSlotData[slot._itself] = nil
        end)
	end
    
    self.trove:Connect(self.hotbar.ChildAdded, function(child: Instance)  
        if child:IsA("Frame") then
            local slotData = Slot.instanceToObjectMap[child]
            if slotData then
                hotbarSlotToSlotData[child] = slotData 
            else
                error("Couldn't find slot data of given slot instance")
            end
        end
    end)
    

    self.trove:Connect(self.hotbar.ChildRemoved, function(child: Instance)  
        if child:IsA("Frame") then
            hotbarSlotToSlotData[child] = nil
        end
    end)

    HotbarManager.toggleKeybindToHotbarSlot(self, true)

    return self
end

function HotbarManager.toggleKeybindToHotbarSlot(self: HotbarObject, toggle : boolean)
    if toggle then
        --warn("enbaling keybindToHotbarSlot")
        self.keybindConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if self.hotbar then
                for _, v in self.hotbar:GetChildren() do
                    if v:IsA("Frame") then
                        if v.LayoutOrder == table.find(hotbarNumberToKeybind, input.KeyCode) then
                            local correspondingHotbarSlot = hotbarSlotToSlotData[v]
                            if correspondingHotbarSlot._isEmpty == false then
                                assert(correspondingHotbarSlot.tool ~= nil)
                                local state = correspondingHotbarSlot.tool:GetAttribute("State")
                                if state == "Unequipping" or state == "Unequipped" then
                                    ToolStateMachine.SetTargets(correspondingHotbarSlot, "Idle")
                                elseif state == "Equipping" or state == "Idle" then
                                    ToolStateMachine.SetTargets(correspondingHotbarSlot, "Unequipped")
                                end
                            end
                        end
                    end
                end
            end
        end)
        if self.hotbar then
            if self.hotbar.GroupTransparency > 0 then
                HotbarManager.GroupTransparency = 0
            end
        else
            error("Need to initialize hotbar first before calling this function")
        end
    else
        --warn("disabling keybindToHotbarSlot")
		if self.keybindConnection ~= nil then
			self.keybindConnection:Disconnect()
		end
        self.keybindConnection = nil
        HotbarManager.GroupTransparency = 0.5
    end
end

function HotbarManager.Destroy(self: HotbarObject)
    if self.keybindConnection then
        self.keybindConnection:Disconnect()
    end
    self.trove:Destroy()
    table.clear(self)
end

return HotbarManager