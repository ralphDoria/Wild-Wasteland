local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    Hit = ItemSystem_Storage.Melee.Remotes.Hit,
    ImpactEffects = ItemSystem_Storage.Melee.Remotes.ImpactEffects,
    ToggleSwingTrail = ItemSystem_Storage.Melee.Remotes.ToggleSwingTrail
}

return function()
    remotes.Hit.OnServerEvent:Connect(function(player: Player, humanoid: Humanoid, damage: number, particles: ParticleEmitter, position: Vector3, normal: Vector3)
        --Maybe add server side sanity checks here later.
        remotes.ImpactEffects:FireAllClients(particles, position, normal)
        humanoid:TakeDamage(damage)  
    end)
    remotes.ToggleSwingTrail.OnServerEvent:Connect(function(player: Player, trail : Trail, toggle : boolean)
        trail.Enabled = toggle
    end)
end
