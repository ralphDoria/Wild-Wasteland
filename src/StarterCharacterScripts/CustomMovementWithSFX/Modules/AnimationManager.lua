local animIDs = {
    sprint = "",
    crouch = "",
    slide = ""
}

local function createAnimTrack(animID : AnimationID, animator : Animator)
    local animObject = Instance.new("Animation")
    animObject.AnimationID = animID
    local animTrack = animator:LoadAnimation(animObject)
    return animTrack
end



local animTracks = {
    
}
--Functional Animation mapping function


local animTracks = {

}

local AnimationManager = {

}

return AnimationManager