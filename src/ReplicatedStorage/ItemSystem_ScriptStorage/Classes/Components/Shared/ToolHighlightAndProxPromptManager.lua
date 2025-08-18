--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local player = game:GetService("Players").LocalPlayer
local ToolSystem_Storage = ReplicatedStorage.ToolSystem_Storage
local highlight: Highlight = ToolSystem_Storage.Shared.Instances.Highlight


local EmptySlotFinder = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.EmptySlotFinder)
local DiegeticErrorMessaging = require(ReplicatedStorage.RojoManaged_RS.DiegeticErrorMessagingManager)
local ToolStateMachine = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.ToolStateMachine.Main_ToolStateMachine)
local Slot = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Slot)

local bindables  = {
    OnPickUp = ToolSystem_Storage.Shared.Bindables.OnPickUp,
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}
local remotes = {
    PickUpTool = ToolSystem_Storage.Shared.Remotes.PickUpTool
}

export type ToolHighlightAndProxPromptManager = {
    tool : Tool,
    highlight : Highlight,
    pp : ProximityPrompt,
    connections : {RBXScriptConnection?}
}

local ToolHighlightAndProxPromptManager = {}

function ToolHighlightAndProxPromptManager.new(tool: Tool) : ToolHighlightAndProxPromptManager
    local self : ToolHighlightAndProxPromptManager = {
        tool = tool,
        highlight = highlight:Clone(),
        pp = Instance.new("ProximityPrompt"),
        connections = {}
    }

    self.highlight.Enabled = false
    self.highlight.Parent = tool
    local pp = self.pp
    pp.ObjectText = tool.Name
    pp.ActionText = "Pick Up"
    pp.MaxActivationDistance = 5
    pp.Style = Enum.ProximityPromptStyle.Custom
    pp.Enabled = false
    pp.RequiresLineOfSight = false
    pp.HoldDuration = 0.5
    pp.Parent = tool:FindFirstChild("BodyAttach", true)
    ToolHighlightAndProxPromptManager._initialize(self)

    return self
end

function ToolHighlightAndProxPromptManager._initialize(self : ToolHighlightAndProxPromptManager)
    
    --Initial check (maybe use observer pattern in the future)
    if self.tool.Parent == workspace then
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
        self.pp.Triggered:Connect(function(thisPlayer: Player) --possible race condition?
            if thisPlayer == player then
                --TODO: this needs to be more robustly coordinated w/ StorageWearable. Perhaps pu these actionNames in a module they can both require
                local actionText = self.pp.ActionText
                if actionText == "Pick Up" then
                    if EmptySlotFinder.any() then
                    self.pp.Enabled = false
                        remotes.PickUpTool:FireServer(self.tool)
                        bindables.OnPickUp:Fire(self.tool) 
                    else
                        DiegeticErrorMessaging.AddMessage("I can't carry any more items")
                    end
                elseif actionText == "Put On" or actionText == "Swap"then
                    self.tool:AddTag("Looted")
                    remotes.PickUpTool:FireServer(self.tool) --for putting the tool into player's backpack
                    bindables.OnPickUp:Fire(self.tool) --for putting tool into the unequipped state
                    warn("Waiting for tool to be picked up")
                    self.tool:GetPropertyChangedSignal("Parent"):Wait() --make sure there are no race conditions involved with this method
                    warn("Tool picked up, starting procedure")

                    local wearableSlot: Slot.SlotObject = Slot.wearableCategoryToObjectMap[self.tool:GetAttribute("WearableCategory")]
                    local temporarySlotObject = Slot.new("Inventory")
                    Slot.FillSlot(temporarySlotObject, self.tool)

                    local tweens = {}
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
                                Slot.FillSlot(wearableSlot, self.tool)
                            elseif not (wearableSlot._isEmpty and temporarySlotObject._isEmpty) then
                                warn("Successfully swapped and wore")
                                -- took off item that was currently worn and put on item in hover slot
                                Slot.destroy(temporarySlotObject)
                                Slot.EmptySlot(wearableSlot)
                                Slot.FillSlot(wearableSlot, self.tool)
                            end
                        end,
                        function(status: string)
                            Slot.ChangeState(wearableSlot, "Idle")
                            self.tool:RemoveTag("Looted")
                        end,
                        function() --onNontargetUnworn
                            bindables.DropToolBindable:Fire(wearableSlot.tool)
                            Slot.EmptySlot(wearableSlot) -- this will cause ItemMovementTracker's onDropped to print a warning, but this is to prevent any race conditions
                        end
                    )
                elseif actionText == "Swap" then
                    local slotObject = Slot.wearableCategoryToObjectMap[self.tool:GetAttribute("WearableCategory")]
                    if not slotObject then
                        error("Didn't find wearable slot")
                    end
                    
                else
                    warn("Unrecognized Action Text")
                end
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
end

function ToolHighlightAndProxPromptManager.Destroy(self: ToolHighlightAndProxPromptManager)
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


return ToolHighlightAndProxPromptManager