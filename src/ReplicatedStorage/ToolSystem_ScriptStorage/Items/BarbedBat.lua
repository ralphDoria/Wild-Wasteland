local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local remotes: {[string] : RemoteEvent} = {
    Hit = ToolSystem_Storage.Melee.Remotes.Hit
}
local particles : {[string] : ParticleEmitter} = {
    blood = ToolSystem_Storage.Melee.Instances.Blood
}

local Melee = require("../Interfaces/Melee")
local Item = require("../Superclasses/Item")
local HitboxManager = require("../Components/HitboxManager")

export type BarbedBatObject = Item.ItemType & {
    damage : number,
    swingSpeed : number,
    HitboxManager : HitboxManager.HitboxManager
}

local BarbedBat =  {}

function BarbedBat.new(tool : Tool, humanoid : Humanoid) : BarbedBatObject
    local self = Item.new(tool, humanoid)
    self.damage = 50
    self.swingSpeed = 1
    self.HitboxManager = HitboxManager.new(tool)

    BarbedBat.initialize(self)

    return self
end

local function toggleSwingBind(self : BarbedBatObject, toggle : boolean)
    local Keycodes = {
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2
    }

    local function foo(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
        if inputState == Enum.UserInputState.Begin then
            BarbedBat.swing(self)
        end
        return Enum.ContextActionResult.Sink
    end
    if toggle then
        ContextActionService:BindAction("swing", foo, true, unpack(Keycodes))
    else
        ContextActionService:UnbindAction("swing")
    end

end

function BarbedBat.initialize(self : BarbedBatObject)
    Item.initialize(
        self,
        nil,
        function()
            toggleSwingBind(self, true)
        end,
        function()
            toggleSwingBind(self, false) 
        end,
        nil)
    local swingTrack = self.animManager.animationTracks[self.tool.Name].swing
    swingTrack:GetMarkerReachedSignal("swing"):Connect(function(status : "start" | "end")
        if self.State ~= "Unequipped" then
            if status == "start" then
                self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].swing :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
                self.HitboxManager.RaycastHitbox:HitStart()
            elseif status == "end" then
                self.HitboxManager.RaycastHitbox:HitStop()
            end 
        end
    end)
    HitboxManager.ConnectOnHit(self.HitboxManager, function(hit: BasePart, humanoid: Humanoid, raycastResult: RaycastResult)  
        local character = humanoid.Parent :: Model
        warn("hit ", character.Name)
        local impactSounds = self.soundManager.Sounds[self.tool.Name].impact :: {[string] : Sound}
        local fleshSound = impactSounds.flesh
        self.soundManager.playSound("Server", fleshSound, self.tool:FindFirstChild("BodyAttach"), 0)
        remotes.Hit:FireServer(humanoid, self.damage, particles.blood, raycastResult.Position, raycastResult.Normal)
    end)
    --The bound action below is for testing purposes; to demonstrate how a faster swing animation somehow inadvertently increases the range
    ContextActionService:BindAction("ChangeSwingSpeed", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?  
        if inputState == Enum.UserInputState.Begin then
            local newSpeed = if self.swingSpeed == 2 then 0.5 else 2
            self.swingSpeed = newSpeed
            warn("Changing swingSpeed to ", newSpeed)
        end
        return Enum.ContextActionResult.Sink
    end, true, Enum.KeyCode.P)
end

function BarbedBat.swing(self : BarbedBatObject)
    if self.State == "Idle" then
        Item.ChangeState(self, "Activated")
        local swingTrack = self.animManager.animationTracks[self.tool.Name].swing
        local vmSwingTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].swing
        local idleTrack = self.animManager.animationTracks[self.tool.Name].idle
        local vmIdleTrack = self.ViewmodelManager.animManager.animationTracks[self.tool.Name].idle
        swingTrack:Play(0.1, 1, self.swingSpeed)
        vmSwingTrack:Play(0.1, 1, self.swingSpeed)
        idleTrack:Stop()
        vmIdleTrack:Stop()
        swingTrack.Stopped:Wait()
        idleTrack:Play()
        vmIdleTrack:Play()
        Item.ChangeState(self, "Idle")
    end
end

return BarbedBat :: Melee.MeleeType<BarbedBatObject>