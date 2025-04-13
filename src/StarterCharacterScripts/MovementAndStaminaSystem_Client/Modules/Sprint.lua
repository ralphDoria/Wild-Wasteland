local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local Config = require(game:GetService("ReplicatedStorage").RojoManaged_RS.CharacterStatsGuiSystem_ScriptStorage.Data.Config)
local ZMovementDirectionUtility = require("./ZMovementDirectionUtility")
local StaminaManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.CharacterStatsGuiSystem_ScriptStorage.Stamina.StaminaManager)local Trove = require(game:GetService("ReplicatedStorage").Packages.Trove)
local trove = Trove.new()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementAndStaminaSystem_Storage = ReplicatedStorage.MovementAndStaminaSystem_Storage
local remotes: {[string]: RemoteEvent} = {
    ChangeHumanoidWalkSpeed = MovementAndStaminaSystem_Storage.Remotes.ChangeHumanoidWalkSpeed
}

local connections: {RBXScriptConnection} = {}

local Sprint = {
    _initialized = false,
    active = false
}

--[[
@note:
Don't have to worry about animations here because the forked Animate script in StarterCharacterScripts handles sprint animation 
(as well as footstep sounds).
]]

local function disconnectAllConnections()
    if connections then
        for _, v in connections do
            v:Disconnect()
            v = nil
        end
    end
end

local function sprintIfMovingForward()
    if ZMovementDirectionUtility.getZDirectionOfMovement() == "Forward" then
        remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Sprint"])
        StaminaManager.drainStaminaBar()
    else
        remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Default"])
        StaminaManager.fillStaminaBar()
    end
end


function Sprint.activate()
    disconnectAllConnections()

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
    disconnectAllConnections()
    remotes.ChangeHumanoidWalkSpeed:FireServer(humanoid, Config.speed["Default"])
    StaminaManager.fillStaminaBar()
    Sprint.active = false
    character:SetAttribute("Sprint", false)
end

function Sprint.initialize()
    if Sprint._initialized then
        warn("Sprint is already initialized")
        return
    end

    humanoid.Died:Once(function(...: any)
        disconnectAllConnections()
        trove:Destroy()
        Sprint._initialized = false
    end)

    Sprint._initialized = true
end

return Sprint