local RS = game:GetService("ReplicatedStorage")
local VitalsSystem_Storage = RS:FindFirstChild("VitalsSystem_Storage", true)
local remotes: {[string]: RemoteEvent} = {
    hungerThirstDamage = VitalsSystem_Storage:FindFirstChild("hungerThirstDamage", true),
    RespawnPlayerCharacter = VitalsSystem_Storage:FindFirstChild("RespawnPlayerCharacter", true)
}

local dmgThreads: {[string]: thread} = {}

local mt = {}
mt.__newindex = function(tbl, i, v)
    if v ~= nil then
        dmgThreads[i] = task.spawn(function()
            while v.humanoid.Health > 0 do
                v.humanoid:TakeDamage(v.damage)
                task.wait(1)
            end
        end)
    else
        if dmgThreads[i] ~= nil then
            task.cancel(dmgThreads[i])
        end
    end
end
local affectedHumanoids = setmetatable({}, mt)

remotes.hungerThirstDamage.OnServerEvent:Connect(function(player: Player, addToTbl: boolean, humanoidToDamage: Humanoid?, damage: number?, timeInterval: number?)
    if addToTbl then
        warn("adding to tbl")
        affectedHumanoids[player.Name] =  {
            humanoid = humanoidToDamage,
            damage = damage
        }
    else
        affectedHumanoids[player.Name] = nil
    end
end)

remotes.RespawnPlayerCharacter.OnServerEvent:Connect(function(player: Player)  
    player:LoadCharacter()
end)