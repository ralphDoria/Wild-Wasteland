--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local player = game:GetService("Players").LocalPlayer
local ToolSystem_Storage = ReplicatedStorage.ToolSystem_Storage
local highlight: Highlight = ToolSystem_Storage.Shared.Instances.Highlight


local findFirstEmptySlot = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.findFirstEmptySlot)
local DiegeticErrorMessaging = require(ReplicatedStorage.RojoManaged_RS.DiegeticErrorMessagingManager)

local bindables : {[string] : BindableEvent} = {
    OnPickUp = ToolSystem_Storage.Shared.Bindables.OnPickUp
}
local remotes: {[string] : RemoteEvent} = {
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
    self.pp.ObjectText = tool.Name
    self.pp.ActionText = "Pick Up"
    self.pp.MaxActivationDistance = 5
    self.pp.Style = Enum.ProximityPromptStyle.Custom
    self.pp.Enabled = false
    self.pp.RequiresLineOfSight = false
    self.pp.HoldDuration = 0.5
    self.pp.Parent = tool:FindFirstChild("BodyAttach", true)
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
                if findFirstEmptySlot() then
                   self.pp.Enabled = false
                    remotes.PickUpTool:FireServer(self.tool)
                    bindables.OnPickUp:Fire(self.tool) 
                else
                    DiegeticErrorMessaging.AddMessage("I can't carry any more items")
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