local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

local AnimationManager = {}

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

local function stopAllCustomAnimations()
    for _, v : AnimationTrack in pairs(animTracks) do
        if v.IsPlaying then
            v:Stop()
        end
    end
end

function AnimationManager.sprintAnimHandler(speed : number)
    --[[
        !!!
        -Roblox's default Animate LocalScript may be able to handle the custom walk animation. Idk though, I have to test.
        -Use animation priority and weighting
    ]]

    --[[
        !!!
        NEED TO REFACTOR CODE BECAUSE ONLY SPRINT SHOULD BE BASED OFF OF CHARACTER SPEED, NOT CROUCH
    ]]
    if speed > (CharacterSpeedInfo.sprintSpeed - 1) then
        doAnimation(animTracks.sprint)
    elseif speed > CharacterSpeedInfo.walkSpeed - 1 then
        animTracks.sprint:Stop()
    elseif speed <= 0 then
        stopAllCustomAnimations()
    end
end

function AnimationManager.crouchAnimHandler(humanoidWalkSpeed)
    if humanoidWalkSpeed == CharacterSpeedInfo.crouchSpeed then
        print("Playing Crouch Ani")
        doAnimation(animTracks.crouch)
    end
end

return AnimationManager