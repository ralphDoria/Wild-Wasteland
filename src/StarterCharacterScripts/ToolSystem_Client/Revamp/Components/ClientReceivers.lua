local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    ImpactEffects = ToolSystem_Storage.Melee.Remotes.ImpactEffects
}
local CreateImpactEffects = require("./CreateImpactEffects")

return function()
    remotes.ImpactEffects.OnClientEvent:Connect(function(particles: ParticleEmitter, position: Vector3, normal: Vector3)  
        CreateImpactEffects(particles, position, normal)
    end)
end
