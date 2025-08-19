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
		local originC0 = M6D.C0
		--[[
		Offsetting the tool's M6D, as show below, aligns this M6D with the character's shoulders, which keeps everything consistent, 
		including the animations, with the TiltCharacterLimbs script.
		the line torso["Right Shoulder"].C0.Y for R6 is probably always equal to 0.5, but I do it for readability.
		]]
		M6D.C0 = originC0 * CFrame.new(Vector3.new(0, torso["Right Shoulder"].C0.Y, 0)) 
        M6D.Parent = torso
		

		character.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				local BodyAttach : Part = child:FindFirstChild("BodyAttach", true)
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

game:GetService("ReplicatedStorage"):WaitForChild("originC0Holder"):WaitForChild("Torso"):WaitForChild("BodyAttachJoint").C0 = CFrame.new(0, 0.5, 0)
game:GetService("ReplicatedStorage"):WaitForChild("Viewmodel"):WaitForChild("Torso"):WaitForChild("BodyAttachJoint").C0 = CFrame.new(0, 0.5, 0)