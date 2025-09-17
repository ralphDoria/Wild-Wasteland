local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    ImpactEffects = ItemSystem_Storage.Melee.Remotes.ImpactEffects
}
local impactEffect = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Gun.Utility.Effects.impactEffect)

return function()
    remotes.ImpactEffects.OnClientEvent:Connect(function(particles: ParticleEmitter, position: Vector3, normal: Vector3)  
        -- CreateImpactEffects(particles, position, normal)
        impactEffect(position, normal, isCharacter, hitMaterial, tool)
    end)
end
