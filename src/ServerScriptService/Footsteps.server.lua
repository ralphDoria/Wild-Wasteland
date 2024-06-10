--[[
    -Authored by @imtocool_2
    -Modified by @Niletheus
]]

local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SFX = ReplicatedStorage:WaitForChild("SFX")
local Sounds = SFX.Footsteps

Players.PlayerAdded:connect(function(Player)
	Player.CharacterAdded:connect(function(Character)
		local Humanoid = Character:WaitForChild("Humanoid")
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

		local Climbing_Speed = 0
		
		Humanoid.Climbing:Connect(function(Speed)
			Climbing_Speed = Speed
		end)
		
		while Humanoid.Health > 0 do
			local Moving = (HumanoidRootPart.Velocity - Vector3.new(0, HumanoidRootPart.Velocity.Y, 0)).Magnitude
			local Rate = (StarterPlayer.CharacterWalkSpeed/3)/Moving
			local Walking = Moving > 2 and Humanoid.FloorMaterial ~= Enum.Material.Air
			
			if Walking or Humanoid:GetState() == Enum.HumanoidStateType.Climbing then
				local Name = "Brick"
				if math.abs(HumanoidRootPart.Velocity.Y) > 0.1 and Humanoid:GetState() == Enum.HumanoidStateType.Climbing then
					Name = "Ladder"

					coroutine.resume(coroutine.create(function()
						local Material_Folder = Sounds:WaitForChild("Ladder"):Clone()
						local Sound = Material_Folder:GetChildren()[math.random(1, #Material_Folder:GetChildren())]:Clone()
						Sound.Parent = HumanoidRootPart
						Sound.Name = Sound.Name
						Sound.PlaybackSpeed = Sound.PlaybackSpeed + math.random(-20, 30)/100
						Sound.Name = Sound.Name .. " (Server Playing)"
						Sound:Play()
						game:GetService(Sound, Sound.TimeLength + 0.1)
						Debris:AddItem(Sound, 5)
					end))
				elseif Walking and Humanoid:GetState() ~= Enum.HumanoidStateType.Climbing then
					if Sounds:FindFirstChild(Humanoid.FloorMaterial.Name) then
						Name = Humanoid.FloorMaterial.Name
					else
						Name = "Brick"
					end

					coroutine.resume(coroutine.create(function()
						local Material_Folder = Sounds:WaitForChild(Name):Clone()
						local Sound = Material_Folder:GetChildren()[math.random(1, #Material_Folder:GetChildren())]:Clone()
						Sound.Parent = HumanoidRootPart
						Sound.Name = Sound.Name .. " (Server Playing)"
						Sound.PlaybackSpeed = Sound.PlaybackSpeed + math.random(-20, 30)/100
						Sound:Play()
						game:GetService(Sound, Sound.TimeLength + 0.1)
						Debris:AddItem(Sound, 5)
					end))
				end
			end
			
			if Walking then
				wait(Rate)
			elseif Humanoid:GetState() == Enum.HumanoidStateType.Climbing then
				local Climb_Rate = (StarterPlayer.CharacterWalkSpeed/3)/math.abs(Climbing_Speed) * 1
				wait(Climb_Rate)
			else
				wait()
			end
		end
	end)
end)