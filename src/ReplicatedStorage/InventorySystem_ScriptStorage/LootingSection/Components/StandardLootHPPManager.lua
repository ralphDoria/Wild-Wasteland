--!strict
local References_Inventory_Client = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local LootingSystem_Storage = References_Inventory_Client.ReplicatedStorage.LootingSystem_Storage
local InventoryScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage

local highlight: Highlight = LootingSystem_Storage.Instances.Highlight

export type HighlightAndProximityPromptManagerObject = {
    instance : Instance,
    highlight : Highlight,
    pp : ProximityPrompt,
    onTriggered: (ProximityPrompt) -> (),
    connections : {[string]: RBXScriptConnection?}
}

local StandardLootHPPManager = {}

function StandardLootHPPManager.new(instance: Instance, proximityPromptParent, onTriggered: (pp: ProximityPrompt) -> ()): HighlightAndProximityPromptManagerObject
    local self : HighlightAndProximityPromptManagerObject = {
        instance = instance,
        highlight = highlight:Clone(),
        pp = Instance.new("ProximityPrompt"),
        onTriggered = onTriggered,
        connections = {}
    }

    self.highlight.Enabled = false
    self.highlight.Parent = instance
    self.pp.ObjectText = instance.Name
    self.pp.ActionText = "Loot"
    self.pp.MaxActivationDistance = 5
    self.pp.Style = Enum.ProximityPromptStyle.Custom
    self.pp.Enabled = false
    self.pp.RequiresLineOfSight = false
    self.pp.HoldDuration = 0.5
    self.pp.Enabled = true
    self.pp.Parent = proximityPromptParent

    StandardLootHPPManager._initialize(self)

    return self
end

function StandardLootHPPManager._initialize(self : HighlightAndProximityPromptManagerObject)
    self.pp.Triggered:Connect(function()  
        self.pp.Enabled = false
        self.onTriggered(self.pp)
    end)
    self.connections.onPromptShown = self.pp.PromptShown:Connect(function(a0: Enum.ProximityPromptInputType)
        if not self.highlight then return end

        self.highlight.Enabled = true
    end)
    self.connections.onPromptHidden = self.pp.PromptHidden:Connect(function(a0: Enum.ProximityPromptInputType)
        if not self.highlight then return end

        self.highlight.Enabled = false
    end)
    self.connections.onHighlightDestroying = self.highlight.Destroying:Once(function(...: any)  
        local shownConnection = self.connections.onPromptShown
        local hiddenConnection = self.connections.onPromptHidden
        if shownConnection then
            shownConnection:Disconnect()
        end
        if hiddenConnection then
            hiddenConnection:Disconnect()
        end
    end)
end

function StandardLootHPPManager.Destroy(self: HighlightAndProximityPromptManagerObject)
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


return StandardLootHPPManager