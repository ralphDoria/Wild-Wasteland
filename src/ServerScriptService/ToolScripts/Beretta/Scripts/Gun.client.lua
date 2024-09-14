local GunController = require(game:GetService("ReplicatedStorage"):FindFirstChild("GunController", true))

print("making a new gun")
local gun : Tool = script.Parent.Parent
local controller = GunController.new(gun)