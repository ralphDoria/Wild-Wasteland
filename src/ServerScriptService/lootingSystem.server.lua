local SoundService = game:GetService("SoundService")
local openSound : Sound = SoundService.SoundStorage.Game.LootContainers.openSound
local closeSound : Sound = SoundService.SoundStorage.Game.LootContainers.closeSound
local playSound = require(game:GetService("ReplicatedStorage"):FindFirstChild("PlaySoundUtil", true))
local rev_toggleOpen = game:GetService("ReplicatedStorage").LootingSystem:FindFirstChild("toggleOpen", true)

local accessing = {}

local openState = false

--[[
    Handles logic and physics related to opening the loot crate container object in the game world.
]]
rev_toggleOpen.OnServerEvent:Connect(function(player : Player, toggle : boolean, hingeConstraint : HingeConstraint)

    hingeConstraint.AngularSpeed = math.huge
    hingeConstraint.ServoMaxTorque = math.huge

    if toggle then
        table.insert(accessing, player)
        if openState == false then
            print("opening")
            openState = true
            hingeConstraint.TargetAngle = -60
            playSound(openSound, hingeConstraint.Parent, 1.1)
        end
    else
        table.remove(accessing, table.find(accessing, player))
        print(accessing)
        if openState == true and #accessing == 0 then
            print("closing")
            openState = false
            hingeConstraint.TargetAngle = 0
            playSound(closeSound, hingeConstraint.Parent, 0.5)
        end
    end
end)
