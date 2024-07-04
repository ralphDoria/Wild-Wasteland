local rev_sprint = game:GetService("ReplicatedStorage"):WaitForChild("CharacterRemotes"):WaitForChild("Sprint")

rev_sprint.OnServerEvent:Connect(function(player, humanoid, activate : boolean)
	if activate then
		humanoid.WalkSpeed = 20
	else
		humanoid.WalkSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed
	end
end)