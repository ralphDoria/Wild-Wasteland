local MeleeController = require(game:GetService("ReplicatedStorage"):FindFirstChild("MeleeController", true))

local melee : Tool = script.Parent.Parent
local controller = MeleeController.new(melee)