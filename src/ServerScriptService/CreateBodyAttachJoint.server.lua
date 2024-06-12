--[[ Purpose

BodyAttach is a part within every one of my tools which is like the root of the tool which every other part of the tool is welded to. A weld needs to be created so that it can be
attached to the player's character when the tool is equipped

Centrally handles creating a BodyAtatchJoint in players' characters & attaching tools to it if the player equips one
]]

local Players = game:GetService("Players")

local function setCollisionGroupInModel(model, CollisionGroupName)
	for _, v in model:GetChildren() do
		if v:IsA("BasePart") then
			v.CollisionGroup = CollisionGroupName
		end
	end
end

Players.PlayerAdded:Connect(function(plr: Player) 
	plr.CharacterAdded:Connect(function(character)
		setCollisionGroupInModel(character, "Character")

		local torso = character:WaitForChild("Torso")

		local M6D = Instance.new("Motor6D")
		M6D.Name = "BodyAttachJoint"
		M6D.Part0 = torso
		M6D.Part1 = nil --temporarily empty, when a tool is equipped, this will be set to the tool's bodyAttach
        M6D.Parent = torso
		

		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				local BodyAttach = child:FindFirstChild("BodyAttach", true)
				if BodyAttach then
					M6D.Part1 = BodyAttach
				else
					warn(child.Name .. " is not a tool that is compatible for this game: missing BodyAttach part")
				end
			end
		end)
		character.ChildRemoved:Connect(function(child)
			if child:IsA("Tool") then
				M6D.Part1 = nil
			end
		end)
	end)	
end)