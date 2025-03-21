local Debris = game:GetService("Debris")

return function(originalParticles: ParticleEmitter, position: Vector3, normal: Vector3)
    local vfx_container = Instance.new("Part") --cling the muzzlepart that is welded to the gun won't clone the weld, which is what I want
    vfx_container.Transparency = 1
    vfx_container.Size = Vector3.new(0.1, 0.1, 0.1)
    vfx_container.Anchored = true
    vfx_container.CanCollide = false
    vfx_container.CanQuery = false --this makes mouse.Hit ignore this part
    vfx_container.Name = "VFX part"
    vfx_container.CFrame = CFrame.lookAlong(position, normal)
    local particles = originalParticles:Clone()
    particles.Enabled = true
    particles.Parent = vfx_container
    vfx_container.Parent = workspace
    task.delay(0.2, function()
        particles.Enabled = false
        --wait for the particles to fade out with Debris
        Debris:AddItem(vfx_container, 1)
    end)
end