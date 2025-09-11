local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris") 

local damageIndicatorTemplate = game:GetService("ReplicatedStorage").ItemSystem_Storage.Shared.Instances.Weapons.ImpactTemplates.DamageIndicatorTemplate


local function damageIndicatorEffect(position: Vector3, normal: Vector3, damageDealt: number, isCriticalHit: boolean)
    local clone = damageIndicatorTemplate:Clone()
    clone.CFrame = CFrame.lookAlong(position, normal)
    clone.Parent = game.Workspace

    
end

-- return function(humanoid : Humanoid, raycastResult : RaycastResult, damageDealt : number, isCriticalHit : boolean)
--     local character = humanoid.Parent

--     --damage indicator for dealer VFX
--     local d = damageIndicatorTemplate:Clone()
--     d.BillboardGui.TextLabel.Text = tostring(damageDealt)
--     if isCriticalHit then
--         d.BillboardGui.TextLabel.TextColor3 = Color3.new(1, 0, 0)
--     end
--     d.Anchored = true
--     d.Position = raycastResult.Position
--     d.Parent = workspace
--     local tweenTime = 1
--     local slideUp = TweenService:Create(
--         d, 
--         TweenInfo.new(tweenTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), 
--         {Position = d.Position + Vector3.new(0, 2, 0)}
--     )
--     local fadeOut = TweenService:Create(
--         d.BillboardGui.TextLabel, 
--         TweenInfo.new(tweenTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), 
--         {TextTransparency = 1}
--     )
--     slideUp:Play()
--     fadeOut:Play()
--     Debris:AddItem(d, tweenTime)
-- end

return damageIndicatorEffect