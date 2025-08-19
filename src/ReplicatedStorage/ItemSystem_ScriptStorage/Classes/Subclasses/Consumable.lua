local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

local consumableRemotes = {
    dispose = References_ItemSystem.ItemSystem_Storage.Consumable.Remotes.Dispose,
}

local particles : {[string] : ParticleEmitter} = {
    -- blood = ItemSystem_Storage.Melee.Instances.Blood
}
-- parent class
local Item = require("../Superclasses/Item")

export type ConsumableObject = Item.ItemType & {
    consumeSpeed: number?,
    activatedEffects: () -> (),
    childClassCleanupFunction: () -> ()
}

local Consumable = {}

function Consumable.new(tool : Tool): ConsumableObject
    local self = Item.new(tool)
    self.consumeSpeed = 1
    -- The two attributes below will be assigned when the initialize function is called (which is called by the child)
    self.childClassCleanupFunction = nil
    self.actionNames.activate = "Activate"

    return self
end

local function toggleInjectBind(self : ConsumableObject, toggle : boolean)
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
            self.actionNames.activate, 
            function(): (() -> (), () -> (), () -> ())  

                local function onActivated()
                    Consumable.activate(self)
                end

                local function onDeactivated()
                    
                end

                local function onUnbind()
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.UserInputType.MouseButton1,
            Enum.KeyCode.ButtonR2, 
            3, 
            nil, 
            nil, 
            "rbxassetid://115384682565092")
    else
        References_ItemSystem.ActionManager.unbindAction(self.actionNames.activate)
    end
end

function Consumable.initialize(self: ConsumableObject, activatedEffects: () -> (), childClassCleanupFunction: () -> ())

    self.activatedEffects = activatedEffects
    self.childClassCleanupFunction = childClassCleanupFunction

    Item.initialize(
        self,
        function()  --onEquipping
        end, 
        function() --onEquipped
            toggleInjectBind(self, true)
        end,
        function() --onUnequipping
            toggleInjectBind(self, false) 
        end,
        function() --onUnequipped()
        end, 
        function() --onDropping()
            toggleInjectBind(self, false)
        end,
        function() --onDropped()
        end
    )

    self.trove:Connect(consumableRemotes.dispose.OnClientEvent, function(tool: Tool)
        if tool ~= self.tool then return end

        if self.childClassCleanupFunction then
            self.childClassCleanupFunction()
        else
            warn("childClassCleanupFunction has not been assigned in Consumable class")
        end
    end)
end

function Consumable.activate(self: ConsumableObject)
    if self.State == "Idle" then
        Item.ChangeState(self, "Activated")
        local activateTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].activate
        local vmActivateTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].activate
        local idleTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].idle
        local vmIdleTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].idle
        activateTrack:Play(0.1, 1, self.consumeSpeed)
        vmActivateTrack:Play(0.1, 1, self.consumeSpeed)
        idleTrack:Stop()
        vmIdleTrack:Stop()
        activateTrack.Stopped:Wait()
        self.activatedEffects()
        idleTrack:Play()
        vmIdleTrack:Play()
        Item.ChangeState(self, "Idle")
        Item.drop(self, function()  
            toggleInjectBind(self, false)
        end)
        consumableRemotes.dispose:FireServer(self.tool)
    end
end

function Consumable.Destroy(self: ConsumableObject, childObjectCleanupMethod: () -> ())
    Item.Destroy(self, function()
        self.consumeSpeed = nil
        toggleInjectBind(self, false)
        childObjectCleanupMethod()
    end)
end

return Consumable