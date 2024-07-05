local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GunController = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Classes"):WaitForChild("GunController"))

print("making a new gun")
local gun : Tool = script.Parent.Parent
local controller = GunController.new(gun)