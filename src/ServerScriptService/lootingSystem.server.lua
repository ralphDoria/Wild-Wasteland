local lootContainer = workspace:FindFirstChild("lootContainer", true)
local lid = lootContainer:FindFirstChild("lid", true)
local pp : ProximityPrompt = lootContainer:FindFirstChildWhichIsA("ProximityPrompt", true)
local hingeConstraint : HingeConstraint = lootContainer:FindFirstChildWhichIsA("HingeConstraint", true)
local openSound : Sound = lootContainer:FindFirstChild("openSound", true)
local closeSound : Sound = lootContainer:FindFirstChild("closeSound", true)
local playSound = require(game:GetService("ReplicatedStorage"):FindFirstChild("PlaySoundUtil", true))
local rev_toggleOpen = game:GetService("ReplicatedStorage").LootingSystem:FindFirstChild("toggleOpen", true)

--Prototype code just to test animation & feel of loot crate

--maybe use a hinge constraint to replace the hard coding below
local original : CFrame = lid.CFrame
local target : CFrame = CFrame.new(752.335999, 188.835693, -61.4820976, 9.7600976e-05, 0.853056133, -0.52182126, -0.00390414149, 0.521817625, 0.853049397, 0.999993324, 0.00195400091, 0.00338137662)

hingeConstraint.TargetAngle = 0
hingeConstraint.AngularSpeed = math.huge
hingeConstraint.ServoMaxTorque = math.huge

local accessing = {}

local openState = false
rev_toggleOpen.OnServerEvent:Connect(function(player : Player, toggle : boolean)
    if toggle then
        table.insert(accessing, player)
        if openState == false then
            print("opening")
            openState = true
            hingeConstraint.TargetAngle = -60
            playSound(openSound, pp.Parent, 1.1)
        end
    else
        table.remove(accessing, table.find(accessing, player))
        print(accessing)
        if openState == true and #accessing == 0 then
            print("closing")
            openState = false
            hingeConstraint.TargetAngle = 0
            playSound(closeSound, pp.Parent, 0.5)
        end
    end
end)
