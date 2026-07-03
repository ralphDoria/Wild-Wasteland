--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

local remotes = {
    heal = References_ItemSystem.ItemSystem_Storage.Consumable.Remotes.Heal
}

-- parent class
local Consumable = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Subclasses.Consumable)

local HealingInjection = {}

function HealingInjection.new(tool): Consumable.ConsumableObject
    local self = Consumable.new(tool)

    HealingInjection._initialize(self)

    return self 
end

function HealingInjection._initialize(self: Consumable.ConsumableObject)
    Consumable.initialize(
        self, 
        function() -- activatedEffects()
            -- The heal amount is server-authoritative (Data/ConsumableStats keyed by the
            -- equipped tool); the server heals the sender's own humanoid (BUGS.md C3).
            remotes.heal:FireServer()
        end,
        function() -- childClassCleanupFunction()
            HealingInjection.Destroy(self)
        end
    )

    local activateTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].activate
    local needleSounds = self.soundObjects.needle
    self.trove:Connect(activateTrack:GetMarkerReachedSignal("needle"), function(status: "insert" | "inject" | "remove")
        if self.State ~= "Unequipped" then
            if status == "insert" then
                References_ItemSystem.remotes.PlaySound:FireServer(needleSounds.insert, self.bodyAttach, 0)
            elseif status == "inject" then
                References_ItemSystem.remotes.PlaySound:FireServer(needleSounds.inject, self.bodyAttach, 0)
            elseif status == "remove" then
                References_ItemSystem.remotes.PlaySound:FireServer(needleSounds.remove, self.bodyAttach, 0)
            end
        end
    end)
end

function HealingInjection.Destroy(self: Consumable.ConsumableObject)
    Consumable.Destroy(self, function()  
        self.tool:SetAttribute("DestroyToolPrompt", true)
    end)
end

return HealingInjection