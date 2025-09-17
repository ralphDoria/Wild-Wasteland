local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes = {
    ReplicateHit = ItemSystem_Storage.Melee.Remotes.ReplicateHit:: UnreliableRemoteEvent,
    ReplicateSwing = ItemSystem_Storage.Melee.Remotes.ReplicateSwing:: UnreliableRemoteEvent,
}
local impactEffect = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Gun.Utility.Effects.impactEffect)

remotes.ReplicateHit.OnClientEvent:Connect(function(particles: ParticleEmitter, position: Vector3, normal: Vector3)  
    -- CreateImpactEffects(particles, position, normal)
    impactEffect(position, normal, true, nil, nil) -- for now, isCharacter parameter will always be true since hit's will only be passed if there's a humanoid
    -- also, latter two parameters can be nil because those are only for guns. I know, bad design on my part
end)

remotes.ReplicateSwing.OnClientEvent:Connect(function(trail: Trail, toggle)
    trail.Enabled = toggle
end)