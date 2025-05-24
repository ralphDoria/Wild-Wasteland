local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Bindables : {[string] : BindableEvent} = {
    ToggleEquip = ReplicatedStorage.ToolSystem_Storage.Shared:FindFirstChild("ToggleEquip", true)
}

type state = "Equipping" | "Idle" | "Unequipping" | "Unequipped" | "Activated"

local EquipToolStateMachine = {}

EquipToolStateMachine.targetTool = nil
local targetToolChangedBindable: BindableEvent = Instance.new("BindableEvent")
local targetToolChanged: RBXScriptSignal = targetToolChangedBindable.Event

function EquipToolStateMachine.SetTargetTool(thisTargetTool: Tool)
    local currentTool = character:FindFirstChildOfClass("Tool")
    if EquipToolStateMachine.targetTool ~= thisTargetTool then
       EquipToolStateMachine.targetTool = thisTargetTool
        targetToolChangedBindable:Fire(thisTargetTool) 
    end

    if currentTool == nil or currentTool == thisTargetTool then
        local state : state = thisTargetTool:GetAttribute("State") :: state
        if state == "Unequipping" or state == "Unequipped" then
            Bindables.ToggleEquip:Fire(thisTargetTool, true)
        elseif state == "Equipping" or state == "Idle" then
            Bindables.ToggleEquip:Fire(thisTargetTool, false)
        end
    else
        -- warn("This feature isn't ready to be tested until you've implemented a tool with an animation different from the Barbed Bat's.")
        local currentToolState : state = currentTool:GetAttribute("State") :: state
        if currentToolState == "Equipping" or currentToolState == "Idle" then
            Bindables.ToggleEquip:Fire(currentTool, false)
            local connection : RBXScriptConnection
            connection = currentTool:GetAttributeChangedSignal("State"):Connect(function(...: any)  
                targetToolChanged:Once(function(newTargetTool)  
                    connection:Disconnect()
                end)

                local newCurrentToolState : state = currentTool:GetAttribute("State") :: state
                if newCurrentToolState == "Unequipped" then
                    connection:Disconnect()
                    Bindables.ToggleEquip:Fire(thisTargetTool, true)
                end
            end)
        elseif currentToolState == "Unequipping" then
            local connection : RBXScriptConnection
            connection = currentTool:GetAttributeChangedSignal("State"):Connect(function(...: any)  
                targetToolChanged:Once(function(newTargetTool)  
                    connection:Disconnect()
                end)

                local newCurrentToolState : state = currentTool:GetAttribute("State") :: state
                if newCurrentToolState == "Unequipped" then
                    connection:Disconnect()
                    Bindables.ToggleEquip:Fire(thisTargetTool, true)
                end
            end)
        end
    end
end


return EquipToolStateMachine