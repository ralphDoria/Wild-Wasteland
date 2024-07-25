--For guns
local Debris = game:GetService("Debris")

local sharedVFX = game:GetService("ReplicatedStorage").Tools.Shared.VFX
local sparkParticles : ParticleEmitter = sharedVFX.sparks
local smokeParticles : ParticleEmitter = sharedVFX.smoke
local blood = sharedVFX.Blood

--[[
    Apparently RaycastResult can't be sent over RemoteEvents (it just sends nil), so that's why I'm using 
    castResultInfo here.
]]
return function(impactPosition : Vector3, castResultInfo : { [any]: any })
    assert(castResultInfo ~= nil, "castResultInfo is nil")
    local vfx_container = Instance.new("Part") --cling the muzzlepart that is welded to the gun won't clone the weld, which is what I want
    vfx_container.Transparency = 1
    vfx_container.Size = Vector3.new(0.1, 0.1, 0.1)
    vfx_container.Anchored = true
    vfx_container.CanCollide = false
    vfx_container.CanQuery = false --this makes mouse.Hit ignore this part
    vfx_container.Name = "VFX part"

    vfx_container.CFrame = CFrame.lookAlong(impactPosition, castResultInfo.Normal)

    local impactParticles : ParticleEmitter
    if castResultInfo.hitHumanoid then
        impactParticles = blood:Clone()
    elseif castResultInfo.Material == Enum.Material.Metal or castResultInfo.Material == Enum.Material.CorrodedMetal or castResultInfo.Material == Enum.Material.DiamondPlate then
        impactParticles = sparkParticles:Clone()
    else
        impactParticles = smokeParticles:Clone()
    end
    impactParticles.Parent = vfx_container

    vfx_container.Parent = workspace

    task.spawn(function()
        task.wait(0.2)
        if impactParticles then
            impactParticles.Enabled = false
        end
        --wait for the particles to fade out with Debris
        Debris:AddItem(vfx_container, 1)
    end)
end