local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_replicateBulletEffects : RemoteEvent = ReplicatedStorage.Tools.Gun.Remotes.ReplicateBulletEffects
local rev_replicateMeleeImpactEffects : RemoteEvent = ReplicatedStorage.Tools.Melee.Remotes.ReplicateMeleeImpactEffects

local createBulletEffects = require(ReplicatedStorage.RojoManaged_RS.Utility.createBulletEffects)

rev_replicateBulletEffects.OnClientEvent:Connect(function(muzzlePart : BasePart, bulletEndPosition : Vector3, castResultMaterial : Enum.Material, castResultNormal : Vector3)
    createBulletEffects(muzzlePart, bulletEndPosition, castResultMaterial, castResultNormal)
end)

rev_replicateMeleeImpactEffects.OnClientEvent:Connect(function()

end)