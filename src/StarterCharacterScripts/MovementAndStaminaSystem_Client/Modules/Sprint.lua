local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local Config = require("./Config")
local ZMovementDirectionUtility = require("./ZMovementDirectionUtility")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementAndStaminaSystem_Storage = ReplicatedStorage.MovementAndStaminaSystem_Storage
local remotes: {[string]: RemoteEvent} = {
    ChangeHumanoidWalkSpeed = MovementAndStaminaSystem_Storage.Remotes.ChangeHumanoidWalkSpeed
}

local connections: {RBXScriptConnection} = {}

local Sprint = {
    active = false
}

--[[
@note:
Don't have to worry about animations here because the forked Animate script in StarterCharacterScripts handles sprint animation 
(as well as footstep sounds).
]]

local function sprintIfMovingForward()
    if ZMovementDirectionUtility.getZDirectionOfMovement() == "Forward" then
        remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Sprint"])
    else
        remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Default"])
    end
end


function Sprint.activate()
    if connections then
        for _, v in connections do
            v:Disconnect()
            v = nil
        end
    end

    -- Initial check
    sprintIfMovingForward()

    -- When zMovementDirection changes
    table.insert(
        connections,
        ZMovementDirectionUtility.zMovementDirectionChanged:Connect(function()  
            sprintIfMovingForward()
        end)
    )

    Sprint.active = true
    character:SetAttribute("Sprint", true)
end

function Sprint.deactivate()
    if connections then
        for _, v in connections do
            v:Disconnect()
            v = nil
        end
    end
    remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Default"])
    Sprint.active = false
    character:SetAttribute("Sprint", false)
end

return Sprint