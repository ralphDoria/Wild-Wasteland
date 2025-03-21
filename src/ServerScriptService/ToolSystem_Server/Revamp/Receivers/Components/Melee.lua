local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    Hit = ToolSystem_Storage.Melee.Remotes.Hit
}

return function()
    remotes.Hit.OnServerEvent:Connect(function(player: Player, humanoid: Humanoid, damage: number)
        --Maybe add server side sanity checks here later.
        humanoid:TakeDamage(damage)  
    end)
end
