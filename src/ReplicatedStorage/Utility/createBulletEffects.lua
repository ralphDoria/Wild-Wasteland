local TweenService = game:GetService("TweenService")
local effects : Folder = game:GetService("ReplicatedStorage").Tools.Gun.Effects
local bulletTracer : Beam = effects.tracer
local sparkParticles : ParticleEmitter = effects.sparks
local smokeParticles : ParticleEmitter = effects.smoke

return function(muzzlePart : BasePart, bulletEndPosition : Vector3, raycastResult : RaycastResult)
    local vfx_container = Instance.new("Part") --cling the muzzlepart that is welded to the gun won't clone the weld, which is what I want
    vfx_container.Transparency = 1
    vfx_container.Size = Vector3.new(0.1, 0.1, 0.1)
    vfx_container.Position = muzzlePart.Position
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

    for _, v in muzzlePart:GetChildren() do
        if v:IsA("ParticleEmitter") or v:IsA("SpotLight") then
            v.Enabled = true
            task.spawn(function()
                task.wait(0.1)
                v.Enabled = false
            end)
        end
    end
    tracer.Parent = vfx_container
    if raycastResult then
        local impactParticles : ParticleEmitter
        if raycastResult.Material == Enum.Material.Metal or raycastResult.Material == Enum.Material.CorrodedMetal or raycastResult.Material == Enum.Material.DiamondPlate then
            impactParticles = sparkParticles:Clone()
        else
            impactParticles = smokeParticles:Clone()
        end
        endBeam.CFrame = CFrame.lookAlong(endBeam.CFrame.Position, raycastResult.Normal)
        impactParticles.Parent = endBeam
    end

    local bulletTravelTime = 0.1
    TweenService:Create(startBeam, TweenInfo.new(bulletTravelTime, Enum.EasingStyle.Exponential, Enum.EasingDirection.In), {CFrame = endBeam.CFrame}):Play()
    task.spawn(function()
        task.wait(bulletTravelTime)
        tracer.Enabled = false
        task.wait(1)
        vfx_container:Destroy()
    end)
end