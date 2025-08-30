return function()
    -- rev_shoot.OnServerEvent:Connect(function(playerWithGun : Player, humanoidToDamage : Humanoid, damageToDeal : number, isHeadshot : boolean, muzzlePart : BasePart, bulletEndPosition : Vector3, castResultInfo : {[any] : any})
    --     --draw raycast for visuals, but hit detection will be done on the client
    --     for _, player in game:GetService("Players"):GetChildren() do
    --         if player ~= playerWithGun then
    --             rev_replicateBulletEffects:FireClient(player, muzzlePart, bulletEndPosition, castResultInfo)
    --         end
    --     end
    --     if humanoidToDamage then
    --         if isHeadshot then
    --             humanoidToDamage:TakeDamage(damageToDeal * 2)
    --         else
    --             humanoidToDamage:TakeDamage(damageToDeal)   
    --         end
    --     end
    -- end)

    -- rev_updateAmmoAttribute.OnServerEvent:Connect(function(player : Player, attributeParent, attributeName : string, newValue : number)
    --     attributeParent:SetAttribute(attributeName, newValue)
    -- end)

    -- rev_reload.OnServerEvent:Connect(function(player : Player)

    -- end)
end
