local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_replicateBulletEffects : RemoteEvent = ReplicatedStorage.Tools.Gun.Remotes.ReplicateBulletEffects
local rev_replicateMeleeImpactEffects : RemoteEvent = ReplicatedStorage.Tools.Melee.Remotes.ReplicateMeleeImpactEffects

local createBulletEffects = require(ReplicatedStorage:FindFirstChild("createBulletEffects", true))
local createImpactEffects = require(ReplicatedStorage:FindFirstChild("createImpactEffects", true))

rev_replicateBulletEffects.OnClientEvent:Connect(function(muzzlePart : BasePart, bulletEndPosition : Vector3, castResultInfo : {[any] : any})
    createBulletEffects(muzzlePart, bulletEndPosition, castResultInfo)
end)

rev_replicateMeleeImpactEffects.OnClientEvent:Connect(function(impactPosition : Vector3, castResultInfo : {[any] : any})
    createImpactEffects(impactPosition, castResultInfo)
end)