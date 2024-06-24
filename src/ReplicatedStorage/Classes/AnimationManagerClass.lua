local AnimationManager = {}
AnimationManager.__index = AnimationManager

--[[
    The animationObjectsTable has to be a dictionary with each key being the name of the animation and the value being the animation object.
    This is because the animationTracks field varaible, which is a table, will be mapped using the animationObjectsTable.
    
    ex.
    animObjects = {
        equip = tool:WaitForChild("Anims"):WaitForChild("equip"),
        idle = tool:WaitForChild("Anims"):WaitForChild("idle"),
        reload = tool:WaitForChild("Anims"):WaitForChild("reload")
    }
]]
function AnimationManager.new(animator : Animator, animationObjectsTable)
    local self = setmetatable({
        animator = animator,
        animationTracks = {}
    },
    AnimationManager)

    for key, animObject in animationObjectsTable do
        self.animationTracks[key] = animator:LoadAnimation(animObject)
        --animTrack.Priority = Enum.AnimationPriority.Action ||| animation priority should be set in animation editor
    end

    return self
end

function AnimationManager:destroy()
    for _, v in pairs(self.animationTracks) do
        v:Destroy()
    end
    self = nil
end


return AnimationManager