local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local Bindables : {[string] : BindableEvent} = {
    ToggleEquip = ReplicatedStorage.ToolSystem_Storage.Shared:FindFirstChild("ToggleEquip", true),
    ToggleWear = ToolSystem_Storage.Wearable.Bindables.ToggleWear
}
local WearableCategory = require("./../WearableCategory")
local Select = require("./../Select")
local SlotType = require("./../SlotType")
local FilledSlotsTracker = require("./../Slot/FilledSlotsTracker")

local Promise = require(ReplicatedStorage.Packages.Promise)

local ItemState = require("./ItemState")
local GetStatePath = require("./GetStatePath")

local currentOperation: {targetSlot: SlotType.SlotType?, targetState: ItemState.ItemState?, connections: {RBXScriptConnection}, promise: any} = {
    targetSlot = nil,
    targetState = nil,
    connections = {},
    promise = nil
}

local function CalculateExpectedPathTime(tool: Tool, statePath: {ItemState.ItemState}): number

    local totalTime: number = 0
    for _, state: ItemState.ItemState in statePath do
        if state == "Equipping" then
            totalTime += tool:GetAttribute("EquipLength"):: number - tool:GetAttribute("EquipTimePosition"):: number
        elseif state == "Unequipping" then
            totalTime += tool:GetAttribute("EquipTimePosition"):: number
        elseif state == "Wearing" then
            totalTime += tool:GetAttribute("WearLength")::number - tool:GetAttribute("WearTimePosition"):: number
        elseif state == "Unwearing" then
            totalTime += tool:GetAttribute("WearTimePosition"):: number
        end
    end

    return totalTime
end

local function WhenToolEntersThisStateDo(tool: Tool, thisState: ItemState.ItemState, doFunction: () -> ()): RBXScriptConnection
    local WaitUntilThisStateEntered: RBXScriptConnection
    WaitUntilThisStateEntered = tool:GetAttributeChangedSignal("State"):Connect(function()
        if tool:GetAttribute("State")::ItemState.ItemState == thisState then
            WaitUntilThisStateEntered:Disconnect()
            doFunction()
        end
    end)
    return WaitUntilThisStateEntered
end

local function CancelCurrentOperation()
    if currentOperation.promise then
        currentOperation.promise:cancel()
        currentOperation.promise = nil
    end
    for _, v in currentOperation.connections do
        v:Disconnect()
    end
    currentOperation.connections = {}
end

local targetsChangedBindable: BindableEvent = Instance.new("BindableEvent")
local targetsChanged: RBXScriptSignal = targetsChangedBindable.Event
local function SetCurrentOperation(slot: SlotType.SlotType, state: ItemState.ItemState)
    targetsChangedBindable:Fire(currentOperation.targetSlot, slot, state)
    currentOperation.targetState = state
    currentOperation.targetSlot = slot
end

targetsChanged:Connect(function(oldSlot, newSlot, newTargetState)  
    if oldSlot then
        Select.removeEffect(oldSlot)
    end
    if newSlot and newTargetState == "Idle" then
        Select.applyEffect(newSlot)
    end
end)

local function GetToolToThisState(tool: Tool, statePath: {ItemState.ItemState}) --:: Promise (don't know if there is a Promise type)
    return Promise.new(function(resolve, reject, onCancel)

        local targetState = statePath[#statePath]
        local startState: ItemState.ItemState = statePath[1]

        onCancel(function() -- Registering a callback to be called if this promise gets cancelled
            print(`Cancelled: ({tool.Name}) {startState} --> {targetState}`)
        end)

        if statePath then
            -- warn(tool.Name, statePath)

            for i = 2, #statePath, 1 do -- start at 2 to ignore the startState
                local previousState: ItemState.ItemState = statePath[i - 1]
                local thisState: ItemState.ItemState = statePath[i]

                if thisState == targetState then
                    table.insert(
                        currentOperation.connections,
                        WhenToolEntersThisStateDo(tool, thisState, function()  
                            -- print(tool.Name, "made it to target state:", targetState)
                            resolve(`Resolved: ({tool.Name}) {startState} --> {targetState}`)
                        end)
                    )
                end

                if thisState == "Equipping" then
                
                    if previousState == startState then
                        Bindables.ToggleEquip:Fire(tool, true)
                    else
                        table.insert(
                            currentOperation.connections,
                            WhenToolEntersThisStateDo(tool, previousState, function()  
                                Bindables.ToggleEquip:Fire(tool, true)
                            end)
                        )
                    end

                elseif thisState == "Unequipping" then

                    if previousState == startState then
                        Bindables.ToggleEquip:Fire(tool, false)
                    else
                        table.insert(
                            currentOperation.connections,
                            WhenToolEntersThisStateDo(tool, previousState, function()  
                                Bindables.ToggleEquip:Fire(tool, false)
                            end)
                        )
                    end

                elseif thisState == "Wearing" then

                    if previousState == startState then
                        Bindables.ToggleWear:Fire(tool, true)
                    else
                        table.insert(
                            currentOperation.connections,
                            WhenToolEntersThisStateDo(tool, previousState, function()  
                                Bindables.ToggleWear:Fire(tool, true)
                            end)
                        )
                    end  

                elseif thisState == "Unwearing" then

                    if previousState == startState then
                        Bindables.ToggleWear:Fire(tool, false)
                    else
                        table.insert(
                            currentOperation.connections,
                            WhenToolEntersThisStateDo(tool, previousState, function()  
                                Bindables.ToggleWear:Fire(tool, false)
                            end)
                        )
                    end      

                end      
            end
        else
            warn("No state path found")
            reject(`Rejected: ({tool.Name}) {startState} --> {targetState}`)
        end
    end)
end

local function GetCurrentWornItemOfCategory(category: WearableCategory.WearableCategoryType): Tool?
    local WornItems: Folder = player.Backpack:FindFirstChild("WornItems")
    local wearableCategoryFolder: Folder = WornItems:FindFirstChild(category):: Folder
    local currentlyWornTool: Tool? = wearableCategoryFolder:FindFirstChildOfClass("Tool"):: Tool?
    return currentlyWornTool
end

local function GetCurrentNonUnequippedToolAndItsState(): (Tool?, ItemState.ItemState?)
    local currentNonUnequippedTool = character:FindFirstChildOfClass("Tool")
    local state: ItemState.ItemState?
    if currentNonUnequippedTool then
        state = currentNonUnequippedTool:GetAttribute("State")
    end
    return currentNonUnequippedTool, state
end

local ToolStateMachine = {}

function ToolStateMachine.SetTargets(target_slot: SlotType.SlotType, target_state: ItemState.ItemState, onValidated: ((number) -> ())?,onFinished: ((string) -> ())?)

    local target_tool: Tool = target_slot.tool:: Tool

    -- Checks to immediately end function
    local targetToolIsInTargetState: boolean = target_tool:GetAttribute("State"):: ItemState.ItemState == target_state
    local targetsAreAlreadyInOperation: boolean = target_slot == currentOperation.targetSlot and target_state == currentOperation.targetState
    if targetToolIsInTargetState or targetsAreAlreadyInOperation then return end


    local currentTool: Tool?, currentState: ItemState.ItemState? = GetCurrentNonUnequippedToolAndItsState()
    local statePathToUnequipped
    if currentTool and currentTool ~= target_tool then
        statePathToUnequipped = GetStatePath(currentState:: ItemState.ItemState, "Unequipped")
    end

    local currentWornTool: Tool?
    local statePathToUnworn
    if target_state == "Worn" then
        currentWornTool = GetCurrentWornItemOfCategory(target_tool:GetAttribute("WearableCategory"):: WearableCategory.WearableCategoryType)
        if currentWornTool and currentWornTool ~= target_tool then
            statePathToUnworn = GetStatePath("Worn", "Unequipped") 
        end
    end

    local statePathToTarget = GetStatePath(target_tool:GetAttribute("State"):: ItemState.ItemState, target_state)

    local function isEmptyTable(tbl: {ItemState.ItemState}?)
        if tbl then
            return #tbl == 0
        else
            return false
        end
    end

    -- warn(statePathToUnequipped, statePathToUnworn, statePathToTarget)
    if isEmptyTable(statePathToUnequipped) or isEmptyTable(statePathToUnworn) or isEmptyTable(statePathToTarget) then
        warn("Viable required tool path not found")
        if onFinished then
            onFinished("Never Ran") 
        end
        return
    else
        -- warn("Proceeding and setting target slot")
        CancelCurrentOperation()
        SetCurrentOperation(target_slot, target_state)
    end

    local estimatedPathsTime = 0

    if statePathToUnequipped then
        estimatedPathsTime += CalculateExpectedPathTime(currentTool:: Tool, statePathToUnequipped)
        currentOperation.promise = GetToolToThisState(currentTool:: Tool, statePathToUnequipped)
    end


    if statePathToUnworn then
        estimatedPathsTime += CalculateExpectedPathTime(currentWornTool:: Tool, statePathToUnworn)
        if currentOperation.promise then
            currentOperation.promise = currentOperation.promise:andThen(function(result)
                print(result)
                return GetToolToThisState(currentWornTool:: Tool, statePathToUnworn)
            end)
        else
            currentOperation.promise = GetToolToThisState(currentWornTool:: Tool, statePathToUnworn)
        end
    end

    if statePathToTarget then
        estimatedPathsTime += CalculateExpectedPathTime(target_tool, statePathToTarget)
        if currentOperation.promise then
            currentOperation.promise = currentOperation.promise:andThen(function(result)
                print(result)
                return GetToolToThisState(target_tool:: Tool, statePathToTarget)
            end)
        else
            currentOperation.promise = GetToolToThisState(target_tool:: Tool, statePathToTarget)
        end

        currentOperation.promise:catch(function(error)
            warn("Error", tostring(error))
        end):finally(function(status)
            warn("currentOperation finished, Status: ", status)
            if onFinished then
                onFinished(status)
            end
        end)

    end

    if onValidated then
        onValidated(estimatedPathsTime)
    end
end

return ToolStateMachine