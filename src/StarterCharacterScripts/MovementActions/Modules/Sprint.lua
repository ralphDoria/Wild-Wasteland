local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid: Humanoid = character:WaitForChild("Humanoid")
local MovementDirectionMonitor = require("./MovementDirectionMonitor")
local StaminaManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.Stamina.StaminaManager)
local Trove = require(game:GetService("ReplicatedStorage").Packages.Trove)
local trove = Trove.new()
local currentStaminaObject = StaminaManager.waitForStaminaObject(character)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MovementAndStaminaSystem_Storage = ReplicatedStorage.MovementAndStaminaSystem_Storage
-- Tier 3 Batch V2: the server owns WalkSpeed now. We send a movement INTENT (a mode
-- name); the server looks the speed up itself and gates Sprint on its own stamina.
-- The remote is created by the server at runtime, hence WaitForChild.
local remotes: { [string]: RemoteEvent } = {
    MovementIntent = MovementAndStaminaSystem_Storage.Remotes:WaitForChild("MovementIntent"),
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

-- Local stamina PREDICTION only (the authoritative sim runs server-side and drains only
-- while it observes movement — this mirrors that gate so the bar doesn't drain standing still).
local function dynamicStaminaPredictionBasedOnIsMoving()

    local function predictIfMoving()
        if MovementDirectionMonitor.isMovingHorizontally() then
            StaminaManager.drainStaminaBar(currentStaminaObject)
        else
            StaminaManager.fillStaminaBar(currentStaminaObject)
        end
    end

     -- Initial check
     predictIfMoving()

    -- When isMoving changes
    table.insert(
        connections,
        MovementDirectionMonitor.isMovingChanged:Connect(function(...: any)
            predictIfMoving()
        end)
    )
end

function Sprint.activate()
    disconnectAllConnections()

    remotes.MovementIntent:FireServer("Sprint")
    dynamicStaminaPredictionBasedOnIsMoving()

    Sprint.active = true
    character:SetAttribute("Sprint", true)
end

function Sprint.deactivate()
    disconnectAllConnections()
    remotes.MovementIntent:FireServer("Default")
    StaminaManager.fillStaminaBar(currentStaminaObject)
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
