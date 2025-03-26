------------------------------------------------------------------------<<<PLAYER SPECIFICS>>>
local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

------------------------------------------------------------------------<<<ROBLOX LIBRARIES>>>
local ReplicatedStorage = game:GetService("ReplicatedStorage")

------------------------------------------------------------------------<<<LOCAL VARIABLES>>>
local CustomMovementAnimations : Folder = ReplicatedStorage:WaitForChild("CustomMovementAnimations")
local animObjects = {
    sprint = CustomMovementAnimations:WaitForChild("sprintAnim"),
    --walk = ---,
    --slide = ---,
    crouch = CustomMovementAnimations:WaitForChild("crouchAnim")
}

local idlePose --can be "standing" or "crouching"

local CharacterSpeedInfo = require(script.Parent.CharacterSpeedInfo)

local function createAnimTrack(animObject : Animation)
    local animTrack = animator:LoadAnimation(animObject)
    return animTrack
end

--Functional programming mapping function (it's for when you need to transform a table, but in slightly different forms each type, but I just did it for practice here.)
--[[
    local function map(tbl, mapping)
    local newTbl = table.create(#tbl)
    
    for key, value in pairs(tbl) do
        print(key)
        print(mapping(value))
        newTbl.key = mapping(value)
    end

    return newTbl
end

local animTracks = map(animObjects, function(animObject)
    createAnimTrack(animObject)
end)
]]

local animTracks = {}
for key, value in pairs(animObjects) do
    animTracks[key] = createAnimTrack(value)
end

------------------------------------------------------------------------<<<LOCAL FUNCTIONS>>>
--[[
    Ensures that only one animation plays at a time. This is a temporary solution because I don't
    know how to use animation weighting yet.
]]
local function doAnimation(animTrack)
    animTrack:Play()
    for _, v in pairs(animTracks) do
        if v ~= animTrack then
            v:Stop()
        end
    end
end

------------------------------------------------------------------------<<<MODULE SCRIPT>>>
local AnimationManager = {}

function AnimationManager.sprintAnimHandler(speed : number)
    if speed > (CharacterSpeedInfo.sprintSpeed - 1) then
        doAnimation(animTracks.sprint)
    else
        animTracks.sprint:Stop()
    end
end

function AnimationManager.crouchAnimHandler(humanoidWalkSpeed)
    if humanoidWalkSpeed == CharacterSpeedInfo.crouchSpeed then
        doAnimation(animTracks.crouch)
    else
        animTracks.crouch:Stop()
    end
end

return AnimationManager