local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local gunRemotesFolder = ReplicatedStorage.ItemSystem_Storage.Gun.Remotes
local gunRemotes = {
    shoot = gunRemotesFolder.Shoot:: RemoteEvent,
    reload = gunRemotesFolder.Reload:: RemoteEvent,
    replicateShot = gunRemotesFolder.ReplicateShot:: UnreliableRemoteEvent,
	replicateItemSound = gunRemotesFolder.ReplicateItemSound:: UnreliableRemoteEvent,
}

local GunComponents = ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Gun
local Constants = require(GunComponents.Constants)
local getRayDirections = require(GunComponents.Utility.getRayDirections)
local castRays = require(GunComponents.Utility.castRays)

local ServerChecks = script.Parent.ServerChecks
local validateShootArguments = require(ServerChecks.validateShootArguments)
local validateShot = require(ServerChecks.validateShot)
local validateTag = require(ServerChecks.validateTag)
local validateReload = require(ServerChecks.validateReload)
local validateInstance = require(script.Parent.TypeValidation.validateInstance)

return function()
    --LEGACY CODE
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
    gunRemotes.shoot.OnServerEvent:Connect(function(
        player: Player, 
        timeStamp: number,
        gun: Tool,
        origin: CFrame,
        tagged: { [string]: Humanoid }
    )  
    -- Validate the received arguments
        if not validateShootArguments(timeStamp, gun, origin, tagged) then
            return
        end

        -- Validate that the player can make this shot
        if not validateShot(player, timeStamp, gun, origin) then
            return
        end

        local spread = gun:GetAttribute(Constants.SPREAD_ATTRIBUTE)
        local raysPerShot = gun:GetAttribute(Constants.RAYS_PER_SHOT_ATTRIBUTE)
        local range = gun:GetAttribute(Constants.RANGE_ATTRIBUTE)
        local rayRadius = gun:GetAttribute(Constants.RAY_RADIUS_ATTRIBUTE)
        local damage = gun:GetAttribute(Constants.DAMAGE_ATTRIBUTE)

        -- Subtract ammo
        local ammo = gun:GetAttribute(Constants.AMMO_ATTRIBUTE)
        gun:SetAttribute(Constants.AMMO_ATTRIBUTE, ammo - 1)

        -- The timestamp that was passed by the client also serves as the seed for the blaster's random spread.
        -- This allows us to recalculate the spread accurately on the server relative to the look direction, rather than simply
        -- accepting a direction or directions from the client.
        local spreadAngle = math.rad(spread)
        local rayDirections = getRayDirections(origin, raysPerShot, spreadAngle, timeStamp)
        for index, direction in rayDirections do
            rayDirections[index] = direction * range
        end
        -- Raycast against static geometry only
        local rayResults = castRays(player, origin.Position, rayDirections, rayRadius, true)

        -- Validate hits
        for indexString, taggedHumanoid in tagged do
            -- The tagged table contains a client-reported list of the humanoids hit by each of the rays that was fired.
            -- Strings are used for the indices since non-contiguous arrays do not get passed over the network correctly.
            -- (This may be non-contiguous in the case of firing a shotgun, where not all of the rays hit a target)
            -- For each humanoid that the client reports it tagged, we'll validate against the ray that was recast on the server.
            local index = tonumber(indexString)
            if not index then
                continue
            end
            local rayResult = rayResults[index]
            if not rayResults[index] then
                continue
            end
            local rayDirection = rayDirections[index]
            if not rayDirection then
                continue
            end

            -- Validate that the player is able to tag this humanoid based on the server raycast
            if not validateTag(player, taggedHumanoid, origin.Position, rayDirection, rayResult) then
                continue
            end

            rayResult.taggedHumanoid = taggedHumanoid

            -- Align the rayResult position to the tagged humanoid. This is necessary so that when we replicate
            -- this shot to the other clients they don't see lasers going through characters they should be hitting.
            local model = taggedHumanoid:FindFirstAncestorOfClass("Model")
            if model then
                local modelPosition = model:GetPivot().Position
                local distance = (modelPosition - origin.Position).Magnitude
                rayResult.position = origin.Position + rayDirection.Unit * distance
            end

            if taggedHumanoid.Health <= 0 then
                continue
            end

            -- Apply damage and fire any relevant events
            taggedHumanoid:TakeDamage(damage)
            -- taggedEvent:Fire(player, taggedHumanoid, damage)

            --TODO: implement kill banner & xp bar
            -- if taggedHumanoid.Health <= 0 then
            --     eliminatedEvent:Fire(player, taggedHumanoid, damage)
            -- end
        end

        -- Apply physics impulse
        -- This is the most straightforward way to do this, although there will be some latency since the impulse is being applied on the server
        local force = gun:GetAttribute(Constants.UNANCHORED_IMPULSE_FORCE_ATTRIBUTE)
        if force ~= 0 then
            for index, rayResult in rayResults do
                -- We don't want to apply impulses to characters, so we'll skip if we tagged a humanoid
                if rayResult.taggedHumanoid then
                    continue
                end

                if rayResult.instance and rayResult.instance:IsA("BasePart") and not rayResult.instance.Anchored then
                    local direction = rayDirections[index]
                    local impulse = direction * force
                    rayResult.instance:ApplyImpulseAtPosition(impulse, rayResult.position)
                end
            end
        end

        -- Replicate shot to other players
        for _, otherPlayer in Players:GetPlayers() do
            if otherPlayer == player then
                continue
            end

            gunRemotes.replicateShot:FireClient(otherPlayer, gun, origin.Position, rayResults)
        end
    end)

    gunRemotes.reload.OnServerEvent:Connect(function(player: Player, gun: Tool)  
        -- Validate the received argument
        if not validateInstance(gun, "Tool") then
            return
        end

        -- Make sure the player is able to reload this blaster
        if not validateReload(player, gun) then
            return
        end

        local magazineSize = gun:GetAttribute(Constants.MAGAZINE_SIZE_ATTRIBUTE)

        gun:SetAttribute(Constants.AMMO_ATTRIBUTE, magazineSize)
    end)

    gunRemotes.replicateItemSound.OnServerEvent:Connect(function(player: Player, gun: Tool, soundName: string)
        local character = player.Character
        assert(character)
        assert(gun.Parent == character)

        for _, otherPlayer in Players:GetPlayers() do
            if otherPlayer == player then
                continue 
            end

            gunRemotes.replicateItemSound:FireClient(otherPlayer, gun, soundName)
        end
    end)
end