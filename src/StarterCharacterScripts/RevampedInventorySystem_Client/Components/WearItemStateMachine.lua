local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local Bindables : {[string] : BindableEvent} = {
    ToggleEquip = ReplicatedStorage.ToolSystem_Storage.Shared:FindFirstChild("ToggleEquip", true),
    ToggleWear = ToolSystem_Storage.Wearable.Bindables.ToggleWear
}

local Select = require("./Select")
local SlotType = require("./SlotType")

export type itemStates = "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated" 
    | "Wearing" | "Unwearing" | "Worn"
    | "Dropping" | "Dropped" 
    | "Destroying" | "UpdatingCharacter"

local WearItemStateMachine = {}

WearItemStateMachine.targetTool = nil
-- local currentlySelectedSlot: SlotType.SlotType? = nil
-- local targetToolChangedBindable: BindableEvent = Instance.new("BindableEvent")
-- local targetToolChanged: RBXScriptSignal = targetToolChangedBindable.Event

local function WhenToolEntersThisStateDo(tool: Tool, thisState: itemStates, doFunction: () -> ())
    local WaitUntilThisStateEntered: RBXScriptConnection
    WaitUntilThisStateEntered = tool:GetAttributeChangedSignal("State"):Connect(function()
        if tool:GetAttribute("State")::itemStates == thisState then
            WaitUntilThisStateEntered:Disconnect()
            doFunction()
        end
    end)
end

--[[
    THIS FUNCTION YIELDS
]]
function WearItemStateMachine.SetTargetTool(targetSlot: SlotType.SlotType): number
    assert(targetSlot._isEmpty == false, "Target slot is empty")

    local thisTargetTool: Tool = targetSlot.tool :: Tool 
    local currentTool = character:FindFirstChildOfClass("Tool")

    -- In the future, implement this if you want to make wear/unwear animations interuptable by target tool changes
    -- if EquipToolStateMachine.targetTool ~= thisTargetTool then
    --    EquipToolStateMachine.targetTool = thisTargetTool
    --     targetToolChangedBindable:Fire(thisTargetTool) 
    -- end

    local timeUntilWorn = 0

    if currentTool == nil or currentTool == thisTargetTool then
        local state : itemStates = thisTargetTool:GetAttribute("State") :: itemStates
        if state == "Unequipping" or state == "Unequipped" then
            Bindables.ToggleEquip:Fire(thisTargetTool, true)
            WhenToolEntersThisStateDo(thisTargetTool, "Idle", function()  
                Bindables.ToggleWear:Fire(thisTargetTool, true)
                WhenToolEntersThisStateDo(thisTargetTool, "Worn", function()  
                    print("Worn")
                end)
            end)
        elseif state == "Equipping" then
            WhenToolEntersThisStateDo(thisTargetTool, "Idle", function()  
                Bindables.ToggleWear:Fire(thisTargetTool, true)
                WhenToolEntersThisStateDo(thisTargetTool, "Worn", function()  
                    print("Worn")
                end)
            end)
        elseif state == "Idle" then
            Bindables.ToggleWear:Fire(thisTargetTool, true)
            WhenToolEntersThisStateDo(thisTargetTool, "Worn", function()  
                print("Worn")
            end)
        end

        local timeUntilEquip = 
                thisTargetTool:GetAttribute("EquipTime"):: number - thisTargetTool:GetAttribute("EquipTimePosition"):: number
        timeUntilWorn = timeUntilEquip + thisTargetTool:GetAttribute("WearTime"):: number
        return timeUntilWorn
    else
        local currentToolState : itemStates = currentTool:GetAttribute("State") :: itemStates
        if currentToolState == "Equipping" or currentToolState == "Idle" then
            -- Bindables.ToggleEquip:Fire(currentTool, false)
            -- local WaitUntilUnequipped: RBXScriptConnection
            -- WaitUntilUnequipped = currentTool:GetAttributeChangedSignal("State"):Connect(function()
            --     if currentTool:GetAttribute("State"):: itemStates == "Unequipped" then
            --         WaitUntilUnequipped:Disconnect()
            --         Bindables.ToggleEquip:Fire(thisTargetTool, true)
            --         local WaitUntilEquipped: RBXScriptConnection
            --         WaitUntilEquipped = thisTargetTool:GetAttributeChangedSignal("State"):Connect(function()  
            --             if thisTargetTool:GetAttribute("State")::itemStates == "Idle" then
            --                 WaitUntilEquipped:Disconnect()
            --                 Bindables.ToggleWear:Fire(thisTargetTool, true)
            --                 WhenToolIsWornDo(thisTargetTool, function()  
            --                     print("Worn")
            --                 end)
            --             end
            --         end)
            --     end
            -- end)

            Bindables.ToggleEquip:Fire(currentTool, false)
            WhenToolEntersThisStateDo(currentTool, "Unequipped", function()  
                Bindables.ToggleEquip:Fire(thisTargetTool, true)
                WhenToolEntersThisStateDo(thisTargetTool, "Idle", function()  
                    Bindables.ToggleWear:Fire(thisTargetTool, true)
                    WhenToolEntersThisStateDo(thisTargetTool, "Worn", function()  
                        print("Worn")
                    end)
                end)
            end)

            local timeUntilEquip = 
                thisTargetTool:GetAttribute("EquipTime"):: number - thisTargetTool:GetAttribute("EquipTimePosition"):: number
            local timeUntilUnequip: number = currentTool:GetAttribute("EquipTimePosition")
            timeUntilWorn = timeUntilUnequip + timeUntilEquip + thisTargetTool:GetAttribute("WearTime"):: number
            return timeUntilWorn

        elseif currentToolState == "Unequipping" then
            WhenToolEntersThisStateDo(currentTool, "Unequipped", function()  
                Bindables.ToggleEquip:Fire(thisTargetTool, true)
                WhenToolEntersThisStateDo(thisTargetTool, "Idle", function()  
                    Bindables.ToggleWear:Fire(thisTargetTool, true)
                    WhenToolEntersThisStateDo(thisTargetTool, "Worn", function()  
                        print("Worn")
                    end)
                end)
            end)

            local timeUntilEquip = 
                thisTargetTool:GetAttribute("EquipTime"):: number - thisTargetTool:GetAttribute("EquipTimePosition"):: number
            local timeUntilUnequip: number = currentTool:GetAttribute("EquipTimePosition")
            timeUntilWorn = timeUntilUnequip + timeUntilEquip + thisTargetTool:GetAttribute("WearTime"):: number
            return timeUntilWorn

        else
            warn("failed to wear", thisTargetTool.Name)
            return 0
        end
    end
end


return WearItemStateMachine