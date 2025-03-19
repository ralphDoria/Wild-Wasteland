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

function EquipToolStateMachine.SetTargetTool(tool: Tool)
    local currentTool = character:FindFirstChildOfClass("Tool")
    if currentTool == nil or currentTool == tool then
        local state : state = tool:GetAttribute("State") :: state
        if state == "Unequipping" or state == "Unequipped" then
            Bindables.ToggleEquip:Fire(tool, true)
        elseif state == "Equipping" or state == "Idle" then
            Bindables.ToggleEquip:Fire(tool, false)
        end
    else
        warn("This feature isn't ready to be tested until you've implemented a tool with an animation different from the Barbed Bat's.")
        --[[
        local currentToolState : state = currentTool:GetAttribute("State") :: state
        if currentToolState == "Equipping" or currentToolState == "Idle" then
            if EquipToolStateMachine.targetTool == currentTool then return end
            EquipToolStateMachine.targetTool = currentTool
            Bindables.ToggleEquip:Fire(currentTool, false)
            local connection : RBXScriptConnection
            connection = currentTool:GetAttributeChangedSignal("State"):Connect(function(...: any)  
                local newCurrentToolState : state = currentTool:GetAttribute("State") :: state
                print(newCurrentToolState)
                if newCurrentToolState == "Unequipped" then
                    connection:Disconnect()
                    Bindables.ToggleEquip:Fire(tool, true)
                end
            end)
        end
        ]]
    end
end


return EquipToolStateMachine