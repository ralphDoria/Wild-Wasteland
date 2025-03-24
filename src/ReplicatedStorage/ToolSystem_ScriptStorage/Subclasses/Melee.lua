local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local hitmarkerSound : Sound = ToolSystem_Storage.Melee.Instances.hitmarker
local remotes: {[string] : RemoteEvent} = {
    Hit = ToolSystem_Storage.Melee.Remotes.Hit,
    ToggleSwingTrail = ToolSystem_Storage.Melee.Remotes.ToggleSwingTrail
}
local particles : {[string] : ParticleEmitter} = {
    blood = ToolSystem_Storage.Melee.Instances.Blood
}

local Item = require("../Superclasses/Item")
local HitboxManager = require("../Components/Shared/HitboxManager")
local ToolGuiManager = require("../Components/Shared/ToolGuiManager")
local MeleeVMM = require("../Components/Melee/MeleeVMM")
local CrosshairGuiManager = require("../Components/Shared/CrosshairManager")
local CameraShaker = require(ReplicatedStorage.Packages.CameraShaker)
local currentCamera = workspace.CurrentCamera
local camShake = CameraShaker.new(Enum.RenderPriority.Last.Value, function(shakeCF)
    currentCamera.CFrame *= shakeCF
end)
camShake:Start()

local crosshairID : string = "rbxassetid://122059927774494"

export type MeleeObject = Item.ItemType & {
    damage : number,
    swingSpeed : number,
    HitboxManager : HitboxManager.HitboxManager,
    CrosshairGuiObject : CrosshairGuiManager.CrosshairObject,
    trail : Trail
}

local ActionNameToKeycodesMapping : {[string] : {Enum.UserInputType | Enum.KeyCode}} = {
    ["Swing"] = {
        Enum.UserInputType.MouseButton1,
        Enum.KeyCode.ButtonR2
    }
}

local ActionNameToLayoutOrderMapping : {[string] : number} = {
    ["Swing"] = -1
}

local Melee =  {}

function Melee.new(tool : Tool, humanoid : Humanoid) : MeleeObject
    local self = Item.new(tool, humanoid)
    self.damage = 50
    self.swingSpeed = 1
    self.HitboxManager = HitboxManager.new(tool)
    self.CrosshairGuiObject = CrosshairGuiManager.new()
    self.trail = tool:FindFirstChildWhichIsA("Trail", true)

    Melee.toggleSwingTrail(self, false)
    for actionName, keycodes in ActionNameToKeycodesMapping do
        ToolGuiManager.CreateInputGui(self.ToolGuiManager, tool, actionName, ActionNameToKeycodesMapping[actionName], ActionNameToLayoutOrderMapping[actionName])
    end 

    Melee.initialize(self)

    return self
end

local function toggleSwingBind(self : MeleeObject, toggle : boolean)
    local function foo(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?
        if inputState == Enum.UserInputState.Begin then
            Melee.swing(self)
        end
        return Enum.ContextActionResult.Sink
    end
    if toggle then
        ContextActionService:BindAction("Swing", foo, true, unpack(ActionNameToKeycodesMapping["Swing"]))
    else
        ContextActionService:UnbindAction("Swing")
    end

end

function Melee.initialize(self : MeleeObject)
    Item.initialize(
        self,
        function()  --onEquipping
            CrosshairGuiManager.toggleEnable(self.CrosshairGuiObject)
        end, 
        function() --onEquipped
            toggleSwingBind(self, true)
        end,
        function() --onUnequipping
            toggleSwingBind(self, false) 
        end,
        function() --onUnequipped()
            CrosshairGuiManager.ForceDisable(self.CrosshairGuiObject)
        end, 
        function() --onDropped()
            CrosshairGuiManager.ForceDisable(self.CrosshairGuiObject)
        end
    )
    MeleeVMM.ConnectTrailsTransparencyUpdater(self.ViewmodelManager, self.tool)
    local swingTrack = self.animManager.animationTracks[self.tool.Name].swing
    swingTrack:GetMarkerReachedSignal("swing"):Connect(function(status : "start" | "end")
        if self.State ~= "Unequipped" then
            if status == "start" then
                self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].swing :: Sound, self.tool:FindFirstChild("BodyAttach"), 0)
                self.HitboxManager.RaycastHitbox:HitStart()
                Melee.toggleSwingTrail(self, true)
            elseif status == "end" then
                self.HitboxManager.RaycastHitbox:HitStop()
                Melee.toggleSwingTrail(self, false)
            end 
        end
    end)
    HitboxManager.ConnectOnHit(self.HitboxManager, function(hit: BasePart, humanoid: Humanoid, raycastResult: RaycastResult)

        local character = humanoid.Parent :: Model
        warn("hit ", character.Name)
        local impactSounds = self.soundManager.Sounds[self.tool.Name].impact :: {[string] : Sound}
        local fleshSound = impactSounds.flesh
        self.soundManager.playSound("Server", fleshSound, self.tool:FindFirstChild("BodyAttach"), 0)
        CrosshairGuiManager.showHitmarker(self.CrosshairGuiObject, function()  
            self.soundManager.playSound("Client", hitmarkerSound, self.tool:FindFirstChild("BodyAttach"), 0)
        end)
        camShake:ShakeOnce(3, 5, 0.2, 0.2)
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

    CrosshairGuiManager.toggleCrosshairLines(self.CrosshairGuiObject, false)
end

function Melee.swing(self : MeleeObject)
    if self.State == "Idle" then
        Item.ChangeState(self, "Activated")
        ToolGuiManager.cooldown(self.ToolGuiManager, "Swing", self.tool, self.animManager.animationTracks[self.tool.Name].swing.Length)
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

function Melee.toggleSwingTrail(self : MeleeObject, toggle : boolean)
    remotes.ToggleSwingTrail:FireServer(self.trail, toggle)
    local vmToolTrail : Trail? = self.ViewmodelManager.ToolToVMToolMapping[self.tool]:FindFirstChildWhichIsA("Trail", true)
    if vmToolTrail then
        vmToolTrail.Enabled = toggle
    end
end

return Melee