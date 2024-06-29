local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MeleeController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("MeleeController"))

local melee : Tool = script.Parent.Parent
local controller = MeleeController.new(melee)