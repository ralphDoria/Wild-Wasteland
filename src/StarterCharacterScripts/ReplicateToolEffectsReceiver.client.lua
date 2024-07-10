local ReplicatedStorage = game:GetService("ReplicatedStorage")
local rev_replicateBulletEffects : RemoteEvent = ReplicatedStorage.Tools.Gun.Remotes.ReplicateBulletEffects

local createBulletEffects = require(ReplicatedStorage.RojoManaged_RS.Utility.createBulletEffects)

rev_replicateBulletEffects.OnClientEvent:Connect(function(bulletStartPosition : Vector3, bulletEndPosition : Vector3)
    print("checkpoint 1")
    createBulletEffects(bulletStartPosition, bulletEndPosition)
end)