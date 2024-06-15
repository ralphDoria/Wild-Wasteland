local animIDs = {
    sprint = "rbxassetid://17809481242",
    --walk = "rbxassetid://17833281861", | I might just be able to replace the walk animation in Roblox's Animate script and won't have to worry about it
    crouch = "",
    slide = ""
}

local WalkSpeedInfo = require(script.Parent.WalkSpeedInfo)

local function createAnimTrack(animID : AnimationID, animator : Animator)
    local animObject = Instance.new("Animation")
    animObject.AnimationID = animID
    local animTrack = animator:LoadAnimation(animObject)
    return animTrack
end

--Functional programming mapping function (it's for when you need to transform a table, but in slightly different forms each type, but I just did it for practice here.)
local function map(tbl, mapping)
    local newTbl = table.create(#tbl)
    
    for key, value in pairs(tbl) do
        newTbl.key = mapping(v)
    end
end

local animTracks = map(animIDs, function(animID)
    createAnimTrack(animID)
end)

local AnimationManager = {}

function AnimationManager.playAnimationBasedOnSpeed(speed : Number)
    --[[
        !!!
        -Roblox's default Animate LocalScript may be able to handle the custom walk animation. Idk though, I have to test.
        -Use animation priority and weighting
    ]]

    if speed > (WalkSpeedInfo.sprintSpeed - 1) then
        animTracks.sprint:Play()
        --animTracks.walk:Stop()
    elseif speed > WalkSpeedInfo.walkSpeed then
        animTracks.sprint:Stop()
        --animTracks.walk:Play()
    elseif speed > WalkSpeedInfo.crouchSpeed then
        animTracks.crouch:Play()
        animTracks.sprint:Stop()
        --animTracks.walk:Stop()
    else
        --idle
    end
end

return AnimationManager