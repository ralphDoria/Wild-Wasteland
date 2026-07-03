local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    dispose = ItemSystem_Storage.Consumable.Remotes.Dispose,
    heal = ItemSystem_Storage.Consumable.Remotes.Heal
}

-- Shared server-authority boundary + the server-side consumable config (BUGS.md C3/C4).
local Validation = require(script.Parent.Parent.Validation)
local ConsumableStats = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Data.ConsumableStats)

return function()
    -- The tool the server consumed on each player's last validated heal. Dispose is only honored
    -- for that exact tool (C4 — clients can't schedule deletion of arbitrary instances). Heal
    -- already schedules the destruction itself, so Dispose is just the trigger for the
    -- all-clients cleanup echo the owning client's Consumable object listens for.
    local pendingDispose: { [Player]: Tool } = {}
    local lastUseTimes: { [Player]: number } = {}
    Players.PlayerRemoving:Connect(function(player: Player)
        pendingDispose[player] = nil
        lastUseTimes[player] = nil
    end)

    remotes.heal.OnServerEvent:Connect(function(player: Player)
        -- The client's arguments (humanoid, amount) are IGNORED — sending a negative amount or a
        -- foreign humanoid no longer does anything (C3). The server heals the sender's own
        -- humanoid by the config amount for their *equipped* consumable, and consumes the item
        -- itself so skipping Dispose can't preserve it.
        local character = Validation.getAliveCharacter(player)
        if not character then
            return
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then
            return
        end
        local tool = character:FindFirstChildOfClass("Tool")
        if not tool then
            return
        end
        local stats = ConsumableStats[tool.Name]
        if not stats then
            return -- equipped tool isn't a known consumable
        end

        local now = os.clock()
        local last = lastUseTimes[player]
        if last and now - last < stats.useCooldown then
            return
        end
        lastUseTimes[player] = now

        humanoid.Health = math.min(humanoid.Health + stats.healAmount, humanoid.MaxHealth)

        pendingDispose[player] = tool
        Debris:AddItem(tool, 10)
    end)

    remotes.dispose.OnServerEvent:Connect(function(player: Player, tool: Tool)
        if pendingDispose[player] ~= tool then
            return
        end
        pendingDispose[player] = nil
        remotes.dispose:FireAllClients(tool)
    end)
end
