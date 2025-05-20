local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    dispose = ToolSystem_Storage.Consumable.Remotes.Dispose
}
local particles : {[string] : ParticleEmitter} = {
    -- blood = ToolSystem_Storage.Melee.Instances.Blood
}
local ActionManager = require("../../ActionManagerSystem/ActionManager")
local Item = require("../Superclasses/Item")
local ToolHighlightAndProxPromptManager = require("../Components/Shared/ToolHighlightAndProxPromptManager")

export type ConsumableObject = Item.ItemType & {
    consumeSpeed: number,
    effectType: "Hunger" | "Thirst" | "Stamina" | "Health",
    startActivatedEffects: () -> ()
}

local Consumable = {}

function Consumable.new(tool : Tool, humanoid : Humanoid, startActivatedEffects: () -> ()): ConsumableObject
    local self = Item.new(tool, humanoid)
    self.consumeSpeed = 1
    self.effectType = "Health"  
    self.startActivatedEffects = startActivatedEffects


    Consumable.initialize(self)

    return self
end

local function toggleInjectBind(self : ConsumableObject, toggle : boolean)
    if toggle then
        ActionManager.bindAction(
            "Swing", 
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
        ActionManager.unbindAction("Swing")
    end
end

function Consumable.initialize(self: ConsumableObject)
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
    self.connections.dispose = remotes.dispose.OnClientEvent:Connect(function(...: any)  
        --Basically need to clean all of tool data here
        ToolHighlightAndProxPromptManager.Destroy(self.ToolHighlightAndProxPromptManager)
    end)
end

function Consumable.activate(self: ConsumableObject)
    if self.State == "Idle" then
        Item.ChangeState(self, "Activated")
        local activateTrack = self.animManager.animationTracks[self.tool.Name].activate
        local vmActivateTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].activate
        local idleTrack = self.animManager.animationTracks[self.tool.Name].idle
        local vmIdleTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].idle
        activateTrack:Play(0.1, 1, self.consumeSpeed)
        vmActivateTrack:Play(0.1, 1, self.consumeSpeed)
        idleTrack:Stop()
        vmIdleTrack:Stop()
        activateTrack.Stopped:Wait()
        self.startActivatedEffects()
        idleTrack:Play()
        vmIdleTrack:Play()
        Item.ChangeState(self, "Idle")
        Item.drop(self, function()  
            toggleInjectBind(self, false)
        end)
        remotes.dispose:FireServer(self.tool)
    end
end

function Consumable.destroy(self: ConsumableObject)
    
end

return Consumable