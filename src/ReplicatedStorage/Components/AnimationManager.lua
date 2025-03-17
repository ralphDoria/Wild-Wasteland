--!strict
export type AnimationManager = {
    ["animator"] : Animator,
    ["animationTracks"] : {[string] : {[string] : AnimationTrack}}
}

local AnimationManager = {}

function AnimationManager.new(character : Model?) : AnimationManager
    assert(character ~= nil, "AnimationManager.new failed because character argument is nil.")

    local self = {
        animator = character:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator"),
        animationTracks = {}    
    }

    return self :: AnimationManager
end

function AnimationManager.LoadAnimations(self : AnimationManager, toolName : string, animations : {[string] : Animation})
    if self.animationTracks[toolName] == nil then --if all animations for a particular tool haven't been loaded yet, then they'll be loaded
        self.animationTracks[toolName] = {}
        for key, animObject in animations do
            local loadedTrack = self.animator:LoadAnimation(animObject)
            self.animationTracks[toolName][animObject.Name] = loadedTrack
        end
    end
end

function AnimationManager.destroy(self : AnimationManager)
    self = nil :: any
end


return AnimationManager