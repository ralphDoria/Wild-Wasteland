local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_replicateBulletEffects : RemoteEvent = ReplicatedStorage.Tools.Gun.Remotes.ReplicateBulletEffects

local createBulletEffects = require(ReplicatedStorage.RojoManaged_RS.Utility.createBulletEffects)

rev_replicateBulletEffects.OnClientEvent:Connect(function(muzzlePart : BasePart, bulletEndPosition : Vector3, raycastResult : RaycastResult)
    print("checkpoint 5")
    createBulletEffects(muzzlePart, bulletEndPosition, raycastResult)
end)