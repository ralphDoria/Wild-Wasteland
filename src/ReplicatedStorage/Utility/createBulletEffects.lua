local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local effects : Folder = game:GetService("ReplicatedStorage").Tools.Gun.Effects
local bulletTracer : Beam = effects.tracer
local bulletImpactParticles : ParticleEmitter = effects.bulletImpactParticles

return function(bulletStartPosition : Vector3, bulletEndPosition : Vector3)
    local vfx_container = Instance.new("Part") --cling the muzzlepart that is welded to the gun won't clone the weld, which is what I want
    vfx_container.Transparency = 1
    vfx_container.Size = Vector3.new(0.1, 0.1, 0.1)
    vfx_container.Position = bulletStartPosition
    vfx_container.Anchored = true
    vfx_container.CanCollide = false
    vfx_container.CanQuery = false --this makes mouse.Hit ignore this part
    vfx_container.Name = "VFX part"
    vfx_container.Parent = workspace
    local startBeam = Instance.new("Attachment")
    local endBeam = Instance.new("Attachment")
    startBeam.Parent = vfx_container
    endBeam.Parent = vfx_container
    startBeam.CFrame = CFrame.new() --this positions the start of the beam at the muzzle (remember that attachments use object space)
    endBeam.CFrame = vfx_container.CFrame:ToObjectSpace(CFrame.new(bulletEndPosition))
    local tracer : Beam = bulletTracer:Clone()
    tracer.Attachment0 = startBeam
    tracer.Attachment1 = endBeam
    tracer.Parent = vfx_container
    local impactParticles : ParticleEmitter = bulletImpactParticles:Clone()
    impactParticles.Parent = endBeam

    local bulletTravelTime = 0.1
    TweenService:Create(startBeam, TweenInfo.new(bulletTravelTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = endBeam.CFrame}):Play()
    Debris:AddItem(vfx_container, bulletTravelTime)
end