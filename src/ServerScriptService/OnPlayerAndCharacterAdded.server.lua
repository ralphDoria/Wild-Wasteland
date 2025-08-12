local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player: Player)  
    player.CharacterAdded:Connect(function(character: Model)  
    end)
end)