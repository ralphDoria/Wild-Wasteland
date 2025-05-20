local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    heal = ToolSystem_Storage.Consumable.Remotes.Heal
}
local Consumable = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.Subclasses.Consumable)

local HealingInjection = {}

function HealingInjection.new(tool, humanoid): Consumable.ConsumableObject
    local self = Consumable.new(tool, humanoid, function()
        remotes.heal:FireServer(humanoid, 25)
    end)

    HealingInjection._initialize(self)

    return self 
end

function HealingInjection._initialize(self: Consumable.ConsumableObject)
    local activateTrack = self.animManager.animationTracks[self.tool.Name].activate
    activateTrack:GetMarkerReachedSignal("needle"):Connect(function(status: "insert" | "inject" | "remove")
        if self.State ~= "Unequipped" then
            if status == "insert" then
                self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].needle.insert, self.tool:FindFirstChild("BodyAttach"), 0)
            elseif status == "inject" then
                self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].needle.inject, self.tool:FindFirstChild("BodyAttach"), 0)
            elseif status == "remove" then
                self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].needle.remove, self.tool:FindFirstChild("BodyAttach"), 0)
            end
        end
    end)
end

function HealingInjection.Destroy(self)
    
end

return HealingInjection