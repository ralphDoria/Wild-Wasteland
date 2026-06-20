local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes = {
    Hit = ItemSystem_Storage.Melee.Remotes.Hit:: RemoteEvent,
    Swing = ItemSystem_Storage.Melee.Remotes.Swing:: RemoteEvent,
    ReplicateHit = ItemSystem_Storage.Melee.Remotes.ReplicateHit:: UnreliableRemoteEvent,
    ReplicateSwing = ItemSystem_Storage.Melee.Remotes.ReplicateSwing:: UnreliableRemoteEvent,
}

-- Shared server-authority boundary + the server-side combat config (BUGS.md C6).
local Validation = require(script.Parent.Parent.Validation)
local CombatStats = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Data.CombatStats)

return function()
    -- Swing-rate limit state: player -> (target humanoid -> last-hit os.clock()). Keyed per target
    -- so it caps single-target DPS WITHOUT blocking one swing from cleaving multiple distinct
    -- targets (RaycastHitbox fires Hit once per humanoid). Inner tables are weak-keyed so dead
    -- NPC humanoids get collected instead of accumulating forever.
    local lastHitTimes: { [Player]: { [Humanoid]: number } } = {}
    Players.PlayerRemoving:Connect(function(player: Player)
        lastHitTimes[player] = nil
    end)

    remotes.Hit.OnServerEvent:Connect(function(player: Player, humanoid: Humanoid, _clientDamage: number?, particles: ParticleEmitter, position: Vector3, normal: Vector3)
        -- Sender must be alive.
        local playerChar = Validation.getAliveCharacter(player)
        if not playerChar then
            return
        end

        -- The server picks the weapon (the sender's currently equipped tool) and reads its
        -- authoritative damage from config. The client's `damage` argument is IGNORED — sending
        -- math.huge no longer does anything (C6).
        local tool = playerChar:FindFirstChildOfClass("Tool")
        if not tool then
            return
        end
        local stats = CombatStats[tool.Name]
        if not stats then
            return -- equipped tool isn't a known melee weapon
        end

        -- Target must be a real, living Humanoid in a real character that isn't the attacker.
        if not Validation.isInstance(humanoid, "Humanoid") or humanoid.Health <= 0 then
            return
        end
        local targetChar = humanoid.Parent
        if not targetChar or not targetChar:IsA("Model") or targetChar == playerChar then
            return
        end

        -- Distance sanity check (attacker character to target character).
        local distance = (playerChar:GetPivot().Position - targetChar:GetPivot().Position).Magnitude
        if distance > stats.maxRange then
            return
        end

        -- Swing-rate limit: reject hits on the SAME target faster than the weapon's cooldown.
        local now = os.clock()
        local playerHits = lastHitTimes[player]
        if not playerHits then
            playerHits = setmetatable({}, { __mode = "k" }) :: any
            lastHitTimes[player] = playerHits
        end
        local last = playerHits[humanoid]
        if last and now - last < stats.swingCooldown then
            return
        end
        playerHits[humanoid] = now

        for _, v in Players:GetPlayers() do
            if v ~= player then
                remotes.ReplicateHit:FireClient(v, particles, position, normal)
            end
        end
        humanoid:TakeDamage(stats.damage)
    end)
    remotes.Swing.OnServerEvent:Connect(function(player: Player, tool: Tool, trail : Trail, toggle : boolean)
        local character = player.Character
		if not character then
			warn("[MeleeReceiver] Rejecting Swing: missing player character", player)
			return
		end
        if not Validation.isInstance(tool, "Tool") or tool.Parent ~= character then
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
