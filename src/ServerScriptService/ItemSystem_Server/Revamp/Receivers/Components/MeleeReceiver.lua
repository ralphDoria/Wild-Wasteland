local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    Hit = ItemSystem_Storage.Melee.Remotes.Hit,
    ImpactEffects = ItemSystem_Storage.Melee.Remotes.ImpactEffects,
    ToggleSwingTrail = ItemSystem_Storage.Melee.Remotes.ToggleSwingTrail
}

return function()
    remotes.Hit.OnServerEvent:Connect(function(player: Player, humanoid: Humanoid, damage: number, particles: ParticleEmitter, position: Vector3, normal: Vector3)
        --Maybe add server side sanity checks here later.
        remotes.ImpactEffects:FireAllClients(particles, position, normal)
        humanoid:TakeDamage(damage)  
    end)
    remotes.ToggleSwingTrail.OnServerEvent:Connect(function(player: Player, trail : Trail, toggle : boolean)
        trail.Enabled = toggle
    end)
    -- --[[
    --     VectorFroce approach to applying knockback, but there are two problems. (1) It's delayed & (2) I need to find out how to convert the 
    --     forceDirection to the object space of the attachment which the VectorForce is attached to.
    -- ]]
    -- local function applyKnockback(part : BasePart, forceDirection : Vector3, forceMagnitude : number)
    --     local vf = Instance.new("VectorForce")
    --     local attachment = Instance.new("Attachment")
    --     vf.Enabled = false
    --     attachment.Parent = part
    --     vf.Parent = part
    --     vf.Attachment0 = attachment
    --     attachment.CFrame = CFrame.new()
    --     forceDirection = CFrame.new(forceDirection):ToObjectSpace(attachment.CFrame).Position
    --     vf.Force = forceDirection * forceMagnitude
    --     vf.Enabled = true
    --     Debris:AddItem(vf, 5)
    --     Debris:AddItem(attachment, 5)
    --     task.spawn(function()
    --         task.wait(1)
    --         vf.Enabled = false
    --     end)
    -- end


    -- local function modifyBloodDecalTransparency(tool : Tool, newTransparency : number)
    --     local toolModel = tool.ToolModel
    --     for _, part in toolModel:GetChildren() do
    --         local decal = part:FindFirstChildOfClass("Decal")
    --         if decal and decal.Transparency ~= newTransparency then
    --             for _, eachDecal in part:GetChildren() do
    --                 eachDecal.Transparency = newTransparency
    --             end
    --         end
    --     end
    -- end

end
