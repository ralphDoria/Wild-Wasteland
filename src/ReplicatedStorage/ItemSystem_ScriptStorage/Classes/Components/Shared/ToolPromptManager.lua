--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local player = game:GetService("Players").LocalPlayer
local ItemSystem_Storage = ReplicatedStorage.ItemSystem_Storage
local highlight: Highlight = ItemSystem_Storage.Shared.Instances.Highlight


local EmptySlotFinder = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.EmptySlotFinder)
local StackableSlotFinder = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.StackableSlotFinder)
local DiegeticErrorMessaging = require(ReplicatedStorage.RojoManaged_RS.DiegeticErrorMessagingManager)
local ToolStateMachine = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.ToolStateMachine.Main_ToolStateMachine)
local Slot = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Slot)

local bindables  = {
    OnPickUp = ItemSystem_Storage.Shared.Bindables.OnPickUp,
    DropToolBindable = ItemSystem_Storage.Shared.Bindables.DropToolBindable,
}
local remotes = {
    RequestPickUpTool = ItemSystem_Storage.Shared.Remotes.RequestPickUpTool:: RemoteFunction,
    RequestMergeStackables = ItemSystem_Storage.Stackable.Remotes.RequestMergeStackables:: RemoteFunction,
}

export type ToolPromptManager = {
    tool : Tool,
    highlight : Highlight,
    pp : ProximityPrompt,
    connections : {RBXScriptConnection?}
}

local ToolPromptManager = {}

function ToolPromptManager.new(tool: Tool) : ToolPromptManager
    local self : ToolPromptManager = {
        tool = tool,
        highlight = highlight:Clone(),
        pp = Instance.new("ProximityPrompt"),
        connections = {}
    }

    self.highlight.Enabled = false
    self.highlight.Parent = tool
    local pp = self.pp
    pp.Archivable = false
    pp.ObjectText = tool.Name
    pp.ActionText = "Pick Up"
    pp.MaxActivationDistance = 5
    pp.Style = Enum.ProximityPromptStyle.Custom
    pp.Enabled = false
    pp.RequiresLineOfSight = false
    pp.HoldDuration = 0.5
    
    pp.Parent = tool:WaitForChild("BodyAttach")
    ToolPromptManager._initialize(self)

    -- warn("Created ToolPrompt for", tool)
    return self
end

function ToolPromptManager._initialize(self : ToolPromptManager)
    
    --Initial check (maybe use observer pattern in the future)
    if self.tool:FindFirstAncestor("Workspace") and self.tool.Parent and not self.tool.Parent:FindFirstChild("Humanoid") then
        self.pp.Enabled = true
    else
        self.pp.Enabled = false
    end
    
    table.insert(
        self.connections,
        self.tool.AncestryChanged:Connect(function(child: Instance, parent: Instance?) 
            if parent == workspace then
                self.pp.Enabled = true
            else
                self.pp.Enabled = false
            end
        end)
    )
    table.insert(
        self.connections,
        self.pp.Triggered:Connect(function(thisPlayer: Player) 
            local actionText = self.pp.ActionText
            if actionText == "Pick Up" then

                local currentQuantity = self.tool:GetAttribute("Quantity")
                if currentQuantity then
                   
                    local sourceTool = self.tool
                    local foundUnmaxedStackable: boolean = true
                    while foundUnmaxedStackable and sourceTool.Parent ~= nil do -- remember that stackables are destroyed when their quantity reaches 0
                        local unmaxedStackable = StackableSlotFinder.any(self.tool.Name)
                        if unmaxedStackable == nil then
                            foundUnmaxedStackable = false
                            continue -- continues to empty slot finder
                        else
                            local destinationTool = unmaxedStackable.tool
                            remotes.RequestMergeStackables:InvokeServer(sourceTool, destinationTool) -- this yields until serverside operation completes
                        end
                    end
                    if sourceTool.Parent == nil then
                        return
                    end
                end

                if EmptySlotFinder.any() then
                    self.pp.Enabled = false
                    local isSuccess: boolean = remotes.RequestPickUpTool:InvokeServer(self.tool)
                    if not isSuccess then print("RequestPickUpTool Denied"); return end
                    bindables.OnPickUp:Fire(self.tool) 
                else
                    DiegeticErrorMessaging.AddMessage("I can't carry any more items")
                end
            elseif actionText == "Put On" or actionText == "Swap"then
                ToolPromptManager._putOnOrSwapWearable(actionText, self.tool)
            else
                warn("Unrecognized Action Text")
            end
        end)
    )
    table.insert(
        self.connections,
        self.pp.PromptShown:Connect(function(a0: Enum.ProximityPromptInputType)
            self.highlight.Enabled = true
        end)
    )
    table.insert(
        self.connections,
        self.pp.PromptHidden:Connect(function(a0: Enum.ProximityPromptInputType)
            self.highlight.Enabled = false
        end)
    )
    local isStackable = self.tool:GetAttribute("Quantity") ~= nil
    if isStackable then
        local stackableName = self.tool.Name -- this should already be plural
        local function updateStackablePromptText()
            local currentQuantity = self.tool:GetAttribute("Quantity") 
            return `{currentQuantity} {if currentQuantity == 1 then stackableName:sub(1, stackableName:len() - 1) else stackableName}`
        end

        -- initial set
        self.pp.ObjectText = updateStackablePromptText()  

        table.insert(
            self.connections,
            self.tool:GetAttributeChangedSignal("Quantity"):Connect(function()  
                self.pp.ObjectText = updateStackablePromptText()  
            end)
        )
    end
end

function ToolPromptManager._putOnOrSwapWearable(actionText: string, tool: Tool)
    tool:AddTag("IgnoreInventorySlotAutofill")
    local isSuccess: boolean = remotes.RequestPickUpTool:InvokeServer(tool)
    warn("Waiting for tool to be picked up")
    if not isSuccess then print("RequestPickUpTool Denied"); return end
    bindables.OnPickUp:Fire(tool) --for putting tool into the unequipped state
    task.wait() -- allows task scheduler to switch to necessary event listeners fired to in the above lines (tool creation & pick up bindable)
    local wearableSlot: Slot.SlotObject = Slot.wearableCategoryToObjectMap[tool:GetAttribute("WearableCategory")]
    local temporarySlotObject = Slot.new("Inventory")
    Slot.FillSlot(temporarySlotObject, tool)

    local tweens = {}
    print("Calling ToolStateMachine.SetTargets")
    ToolStateMachine.SetTargets(temporarySlotObject, "Worn", 
        function(estimatedPathsTime: number) -- onValidated
            Slot.ChangeState(temporarySlotObject, "BeingSwapped")
            Slot.ChangeState(wearableSlot, "BeingSwapped")
            table.insert(tweens, Slot.loadSlot(wearableSlot, estimatedPathsTime))  
            for _, v in tweens do
                v:Play()
            end
        end,
        function(completedUnwearing: boolean?) -- onCancelled
            warn("Cancelled")
            for _, v in tweens do
                if v.PlaybackState == Enum.PlaybackState.Playing then
                    v:Cancel()                        
                end
            end
            if actionText == "Put On" then
                bindables.DropToolBindable:Fire(temporarySlotObject.tool)
                Slot.destroy(temporarySlotObject)
            elseif actionText == "Swap" then
                bindables.DropToolBindable:Fire(temporarySlotObject.tool)
                Slot.destroy(temporarySlotObject)
            end
        end,
        function() --onResolved
            if wearableSlot._isEmpty then
                warn("Successfully wore and emptied")
                -- successfull wore item from inventory/hotbar and now emptying its slot and filling it's new place in CharacterEquipmentSlots
                assert(temporarySlotObject.tool)
                Slot.destroy(temporarySlotObject)
                Slot.FillSlot(wearableSlot, tool)
            elseif not (wearableSlot._isEmpty and temporarySlotObject._isEmpty) then
                warn("Successfully swapped and wore")
                -- took off item that was currently worn and put on item in hover slot
                Slot.destroy(temporarySlotObject)
                Slot.EmptySlot(wearableSlot)
                Slot.FillSlot(wearableSlot, tool)
            end
        end,
        function(status: string)
            Slot.ChangeState(wearableSlot, "Idle")
            tool:RemoveTag("IgnoreInventorySlotAutofill")
        end,
        function() --onNontargetUnworn
            bindables.DropToolBindable:Fire(wearableSlot.tool)
            Slot.EmptySlot(wearableSlot) -- this will cause ItemMovementTracker's onDropped to print a warning, but this is to prevent any race conditions
        end
    )
end

function ToolPromptManager.Destroy(self: ToolPromptManager)
    for _, v in self.connections do
        if typeof(v) == "RBXScriptConnection" then
            v:Disconnect()    
        end
        v = nil
    end
    self.highlight:Destroy()
    self.pp:Destroy()
    table.clear(self)
end


return ToolPromptManager