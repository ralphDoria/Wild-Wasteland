local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    Hit = ToolSystem_Storage.Melee.Remotes.Hit,
    ImpactEffects = ToolSystem_Storage.Melee.Remotes.ImpactEffects
}

return function()
    remotes.Hit.OnServerEvent:Connect(function(player: Player, humanoid: Humanoid, damage: number, particles: ParticleEmitter, position: Vector3, normal: Vector3)
        --Maybe add server side sanity checks here later.
        remotes.ImpactEffects:FireAllClients(particles, position, normal)
        humanoid:TakeDamage(damage)  
    end)
end
