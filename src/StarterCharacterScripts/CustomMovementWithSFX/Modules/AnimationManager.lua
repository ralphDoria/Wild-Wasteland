local animIDs = {
    sprint = "rbxassetid://17809481242",
    --walk = "rbxassetid://17833281861", | I might just be able to replace the walk animation in Roblox's Animate script and won't have to worry about it
    crouch = "",
    slide = ""
}

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



return AnimationManager