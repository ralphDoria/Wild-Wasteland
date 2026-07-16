local CollectionService = game:GetService("CollectionService")
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

-- Tier 3 Batch V2: the swing's stamina cost is charged server-side on the validated
-- Swing remote (the client only predicts it).
local VitalsConfig = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.Data.VitalsConfig)
local VitalsService = require(game:GetService("ServerScriptService").RojoManaged_SSS.VitalsSystem_Server.VitalsService)
-- Kill attribution: XP is credited right after lethal damage (docs/XP_SYSTEM_RESEARCH.md).
local XPService = require(game:GetService("ServerScriptService").RojoManaged_SSS.XPSystem_Server.XPService)
-- Placed build structures are melee-hittable: BuildService.damageStructure is the ONLY
-- structure-health mutator (build system v1).
local BuildConfig = require(ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage.Data.BuildConfig)
local BuildService = require(game:GetService("ServerScriptService").RojoManaged_SSS.BuildSystem_Server.BuildService)

return function()
    -- Swing-rate limit state: player -> (target -> last-hit os.clock()). Targets are
    -- humanoids OR placed-structure parts, keyed per target so it caps single-target DPS
    -- WITHOUT blocking one swing from cleaving multiple distinct targets. Inner tables
    -- are weak-keyed so dead humanoids/destroyed structures get collected.
    local lastHitTimes: { [Player]: { [Instance]: number } } = {}
    Players.PlayerRemoving:Connect(function(player: Player)
        lastHitTimes[player] = nil
    end)

    -- Shared per-(player, target) swing-rate limit. Returns false when the hit lands
    -- faster than the equipped weapon's cooldown allows.
    local function passesRateLimit(player: Player, target: Instance, swingCooldown: number): boolean
        local now = os.clock()
        local playerHits = lastHitTimes[player]
        if not playerHits then
            playerHits = setmetatable({}, { __mode = "k" }) :: any
            lastHitTimes[player] = playerHits
        end
        local last = playerHits[target]
        if last and now - last < swingCooldown then
            return false
        end
        playerHits[target] = now
        return true
    end

    remotes.Hit.OnServerEvent:Connect(function(player: Player, target: Instance, _clientDamage: number?, particles: ParticleEmitter, position: Vector3, normal: Vector3)
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

        if Validation.isInstance(target, "Humanoid") then
            local humanoid = target :: Humanoid
            -- Target must be a real, living Humanoid in a real character that isn't the attacker.
            if humanoid.Health <= 0 then
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

            if not passesRateLimit(player, humanoid, stats.swingCooldown) then
                return
            end

            for _, v in Players:GetPlayers() do
                if v ~= player then
                    remotes.ReplicateHit:FireClient(v, particles, position, normal)
                end
            end
            humanoid:TakeDamage(stats.damage)
            XPService.notifyDamageDealt(player, humanoid)
        elseif Validation.isInstance(target, "BasePart") and CollectionService:HasTag(target, BuildConfig.structureTag) then
            local structure = target :: BasePart
            -- Distance vs the PANEL CENTER: an 8x8 panel's center can sit up to half a
            -- cell diagonal (~5.7 studs) from the edge actually struck, hence the slack.
            local distance = (playerChar:GetPivot().Position - structure.Position).Magnitude
            if distance > stats.maxRange + BuildConfig.cellSize * 0.75 then
                return
            end

            if not passesRateLimit(player, structure, stats.swingCooldown) then
                return
            end

            for _, v in Players:GetPlayers() do
                if v ~= player then
                    remotes.ReplicateHit:FireClient(v, particles, position, normal)
                end
            end
            BuildService.damageStructure(structure, stats.damage)
        end
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

        -- One authoritative stamina charge per swing (the client fires toggle=true once
        -- at swing start, false when the trail ends). Only costs the sender.
        if toggle == true and CombatStats[tool.Name] then
            VitalsService.applyStaminaCost(player, VitalsConfig.Stamina.swingCost)
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
