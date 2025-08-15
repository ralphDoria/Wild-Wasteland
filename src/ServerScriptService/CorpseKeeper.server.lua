local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character)
		
		local humanoid = character:WaitForChild("Humanoid"):: Humanoid
		humanoid.BreakJointsOnDeath = false
		
		player.CharacterRemoving:Once(function(_: Model) 
			--table.insert(corpses, character)
			task.defer(function()
				character.Parent = workspace
				-- Debris:AddItem(character, 5)
			end)
		end)
	end)
end)