local function muzzleFlashEffect(muzzlePart: BasePart)
    for _, v in muzzlePart:GetChildren() do
        if v:IsA("ParticleEmitter") or v:IsA("SpotLight") then
            v.Enabled = true
            task.spawn(function()
                task.wait(0.1)
                v.Enabled = false
            end)
        end
    end
end

return muzzleFlashEffect