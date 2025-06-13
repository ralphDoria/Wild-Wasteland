--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Trove = require(ReplicatedStorage.Packages.Trove)
local player = game:GetService("Players").LocalPlayer
local LootingSystem_Storage = ReplicatedStorage.LootingSystem_Storage
local highlight: Highlight = LootingSystem_Storage.Instances.Highlight
local ToggleOVerrideCamModeCursorLock = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.ToggleOverrideCamModeCursorLock)

local bindables : {[string] : BindableEvent} = {
    -- OnPickUp = LootingSystem_Storage.Shared.Bindables.OnPickUp
}
local remotes: {[string] : RemoteEvent} = {
    -- PickUpTool = LootingSystem_Storage.Shared.Remotes.PickUpTool
}

export type HighlightAndProximityPromptManagerObject = {
    instance : Instance,
    highlight : Highlight,
    pp : ProximityPrompt,
    connections : {RBXScriptConnection?}
}

local HighlighAndProximityPromptManager = {}

function HighlighAndProximityPromptManager.new(instance: Instance, proximityPromptParent) : HighlightAndProximityPromptManagerObject
    local self : HighlightAndProximityPromptManagerObject = {
        instance = instance,
        highlight = highlight:Clone(),
        pp = Instance.new("ProximityPrompt"),
        connections = {}
    }

    self.highlight.Enabled = false
    self.highlight.Parent = instance
    self.pp.ObjectText = instance.Name
    self.pp.ActionText = "Pick Up"
    self.pp.MaxActivationDistance = 5
    self.pp.Style = Enum.ProximityPromptStyle.Custom
    self.pp.Enabled = false
    self.pp.RequiresLineOfSight = false
    self.pp.HoldDuration = 0.5
    self.pp.Enabled = true
    self.pp.Parent = proximityPromptParent

    HighlighAndProximityPromptManager._initialize(self)

    return self
end

function HighlighAndProximityPromptManager._initialize(self : HighlightAndProximityPromptManagerObject)
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

function HighlighAndProximityPromptManager.Destroy(self: HighlightAndProximityPromptManagerObject)
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


return HighlighAndProximityPromptManager