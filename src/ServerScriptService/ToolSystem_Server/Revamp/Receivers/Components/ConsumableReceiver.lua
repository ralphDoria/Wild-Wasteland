local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    dispose = ToolSystem_Storage.Consumable.Remotes.Dispose,
    heal = ToolSystem_Storage.Consumable.Remotes.Heal
}
local Debris = game:GetService("Debris")

return function()
    remotes.dispose.OnServerEvent:Connect(function(player: Player, tool: Tool)
        Debris:AddItem(tool, 10)
        remotes.dispose:FireAllClients(tool)
    end)
    remotes.heal.OnServerEvent:Connect(function(a0: Player, humanoid: Humanoid, num: number)  
        humanoid:TakeDamage(-num)
    end)
end
