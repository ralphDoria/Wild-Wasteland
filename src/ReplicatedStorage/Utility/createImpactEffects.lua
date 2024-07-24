--For guns
local Debris = game:GetService("Debris")

local sharedVFX = game:GetService("ReplicatedStorage").Tools.Shared.VFX
local sparkParticles : ParticleEmitter = sharedVFX.sparks
local smokeParticles : ParticleEmitter = sharedVFX.smoke
local blood = sharedVFX.Blood

--[[
    Had to send raycast properties individual because apparently you can't send the RaycastResult Instance
    over remote events because there are "complications with sending dictionaries over remote events".
]]
return function(impactPosition : Vector3, hitHumanoid : boolean, castResultMaterial : Enum.Material, castResultNormal : Vector3)
    if impactPosition then
        local vfx_container = Instance.new("Part") --cling the muzzlepart that is welded to the gun won't clone the weld, which is what I want
        vfx_container.Transparency = 1
        vfx_container.Size = Vector3.new(0.1, 0.1, 0.1)
        vfx_container.Anchored = true
        vfx_container.CanCollide = false
        vfx_container.CanQuery = false --this makes mouse.Hit ignore this part
        vfx_container.Name = "VFX part"

        vfx_container.CFrame = CFrame.lookAlong(impactPosition, castResultNormal)

        local impactParticles : ParticleEmitter
        if hitHumanoid then
            impactParticles = blood:Clone()
        elseif castResultMaterial == Enum.Material.Metal or castResultMaterial == Enum.Material.CorrodedMetal or castResultMaterial == Enum.Material.DiamondPlate then
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
end