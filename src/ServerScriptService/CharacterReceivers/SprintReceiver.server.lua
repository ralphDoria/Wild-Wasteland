local rev_changeWalkSpeed = game:GetService("ReplicatedStorage").CharacterRemotes.ChangeWalkSpeed

rev_changeWalkSpeed.OnServerEvent:Connect(function(player, humanoid, activate : boolean, newWalkSpeed : number)
	if activate then
		humanoid.WalkSpeed = newWalkSpeed
	else
		humanoid.WalkSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed
	end
end)