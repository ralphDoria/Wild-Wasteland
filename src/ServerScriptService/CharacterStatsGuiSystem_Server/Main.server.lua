local RS = game:GetService("ReplicatedStorage")
local CharacterStatsGuiSystem_Storage = RS:FindFirstChild("CharacterStatsGuiSystem_Storage", true)
local remotes: {[string]: RemoteEvent} = {
    hungerThirstDamage = CharacterStatsGuiSystem_Storage:FindFirstChild("hungerThirstDamage", true)
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