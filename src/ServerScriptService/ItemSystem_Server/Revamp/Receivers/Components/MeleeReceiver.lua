local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes = {
    Hit = ItemSystem_Storage.Melee.Remotes.Hit:: RemoteEvent,
    Swing = ItemSystem_Storage.Melee.Remotes.Swing:: RemoteEvent,
    ReplicateHit = ItemSystem_Storage.Melee.Remotes.ReplicateHit:: UnreliableRemoteEvent,
    ReplicateSwing = ItemSystem_Storage.Melee.Remotes.ReplicateSwing:: UnreliableRemoteEvent,
}

return function()
    local _maxHitRange = 10
    remotes.Hit.OnServerEvent:Connect(function(player: Player, humanoid: Humanoid, damage: number, particles: ParticleEmitter, position: Vector3, normal: Vector3)
        local playerChar = player.Character:: Model?
		if not playerChar then
			warn("[MeleeReceiver] Rejecting Hit: missing player character", player)
			return
		end
        local targetChar = humanoid.Parent:: Model?
		if not targetChar then
			warn("[MeleeReceiver] Rejecting Hit: missing target character", humanoid)
			return
		end
        local distance = (playerChar:GetPivot().Position - targetChar:GetPivot().Position).Magnitude
		if distance > _maxHitRange then
			warn("[MeleeReceiver] Rejecting Hit: distance too large", distance)
			return
		end

        for _, v in Players:GetPlayers() do
            if v ~= player then
                remotes.ReplicateHit:FireClient(v, particles, position, normal)
            end
        end
        humanoid:TakeDamage(damage)  
    end)
    remotes.Swing.OnServerEvent:Connect(function(player: Player, tool: Tool, trail : Trail, toggle : boolean)
        local character = player.Character
		if not character then
			warn("[MeleeReceiver] Rejecting Swing: missing player character", player)
			return
		end
        if tool.Parent ~= character then
            warn("[MeleeReceiver] Rejecting Swing: tool not equipped by character", tool, character)
            return
        end

        for _, v in Players:GetPlayers() do
            if v ~= player then
                remotes.ReplicateSwing:FireClient(v, trail, toggle)
            end
        end
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
