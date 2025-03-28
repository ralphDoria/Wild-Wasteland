local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementAndStaminaSystem_Storage = ReplicatedStorage.MovementAndStaminaSystem_Storage
local remotes: {[string]: RemoteEvent} = {
    ChangeHumanoidWalkSpeed = MovementAndStaminaSystem_Storage.Remotes.ChangeHumanoidWalkSpeed
}

remotes.ChangeHumanoidWalkSpeed.OnServerEvent:Connect(function(player: Player, humanoid: Humanoid, walkSpeed: number)
	humanoid.WalkSpeed = walkSpeed
end)