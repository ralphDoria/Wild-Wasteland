local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    ImpactEffects = ItemSystem_Storage.Melee.Remotes.ImpactEffects
}
local CreateImpactEffects = require("./CreateImpactEffects")

return function()
    remotes.ImpactEffects.OnClientEvent:Connect(function(particles: ParticleEmitter, position: Vector3, normal: Vector3)  
        CreateImpactEffects(particles, position, normal)
    end)
end
