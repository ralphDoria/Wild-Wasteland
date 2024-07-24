local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris") 

local sharedVFX = game:GetService("ReplicatedStorage").Tools.Shared.VFX
local damageIndicator = sharedVFX.DamageIndicator

return function(humanoid : Humanoid, raycastResult : RaycastResult, damageDealt : number, isCriticalHit : boolean)
    local character = humanoid.Parent

    --damage indicator for dealer VFX
    local d = damageIndicator:Clone()
    d.BillboardGui.TextLabel.Text = tostring(damageDealt)
    if isCriticalHit then
        d.BillboardGui.TextLabel.TextColor3 = Color3.new(1, 0, 0)
    end
    d.Parent = character
    d.Anchored = false
    local weld = Instance.new("Weld")
    weld.Part0 = character.Head
    weld.Part1 = d
    weld.Name = d.Name
    weld.Parent = character
    local tweenTime = 1
    local slideUp = TweenService:Create(
        weld, 
        TweenInfo.new(tweenTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), 
        {C0 = CFrame.new(0, 2, 0)}
    )
    local fadeOut = TweenService:Create(
        d.BillboardGui.TextLabel, 
        TweenInfo.new(tweenTime, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), 
        {TextTransparency = 1}
    )
    slideUp:Play()
    fadeOut:Play()
    Debris:AddItem(d, tweenTime)
end