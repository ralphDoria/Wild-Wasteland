--!strict
export type AnimationManager = {
    toolTracker: {[string]: {Tool}},
    ["animator"] : Animator,
    ["animationTracks"] : {[string] : {[string] : AnimationTrack}}
}

local AnimationManager = {}

function AnimationManager.new(character : Model?) : AnimationManager
    assert(character ~= nil, "AnimationManager.new failed because character argument is nil.")

    local humanoid = character:FindFirstChildOfClass("Humanoid") :: Humanoid

    local self = {
        toolTracker = {},
        animator = humanoid:FindFirstChildOfClass("Animator"),
        animationTracks = {}    
    }

    return self :: AnimationManager
end

--[[
    This method adds the tool to the tool tracker and loads only if the animations aren't already loaded.
]]
function AnimationManager.LoadAnimations(self : AnimationManager, tool : Tool, animations : {[string] : Animation})
    if self.toolTracker[tool.Name] == nil then
        self.toolTracker[tool.Name] = {tool}
    else
        table.insert(self.toolTracker[tool.Name], tool)
    end
    if self.animationTracks[tool.Name] == nil then --if all animations for a particular tool haven't been loaded yet, then they'll be loaded
        self.animationTracks[tool.Name] = {}
        for key, animObject in animations do
            local loadedTrack = self.animator:LoadAnimation(animObject)
            self.animationTracks[tool.Name][animObject.Name] = loadedTrack
        end
    end
end

--[[
    This method checks if there are any other tools of its type that the AnimationManager is tracking in its toolTracker. If there are, meaing the player is dropping this item, abut it has another item of the same type in
    their invenotry, then the AnimationManager won't destroy the animation tracks associated w/ that tool. If there aren't any other tools of its type, then all animation tracks of this tool will be 
    destroyed to free up memory.
]]
function AnimationManager.RemoveTool(self: AnimationManager, tool: Tool)
    local specificToolTracker = self.toolTracker[tool.Name]
    local i = table.find(specificToolTracker, tool)
    if i then
        table.remove(specificToolTracker, i)
        if #specificToolTracker == 0 then
            print("Destroying all animation tracks for this item becausae there are none left in player's inventory")
            for trackName, v in self.animationTracks[tool.Name] do
                v:Destroy()
                self.animationTracks[tool.Name][trackName] = nil
            end
            self.animationTracks[tool.Name] = nil
        end
    end
end

function AnimationManager.StopAllAnimsForTool(self: AnimationManager, tool: Tool)
    for _, v: AnimationTrack in self.animationTracks[tool.Name] do
        if v.IsPlaying then
            v:Stop()
        end
    end
end

function AnimationManager.Destroy(self : AnimationManager)
    for _: string, trackNameToAnimationTrack: {[string]: AnimationTrack} in self.animationTracks do
        for _, v in trackNameToAnimationTrack do
            v:Destroy()
        end
        table.clear(trackNameToAnimationTrack)
    end
    table.clear(self.animationTracks)
    table.clear(self.toolTracker)
    table.clear(self)
end


return AnimationManager