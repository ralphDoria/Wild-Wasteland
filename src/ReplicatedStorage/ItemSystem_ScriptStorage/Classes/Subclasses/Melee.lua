local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local hitmarkerSound : Sound = ItemSystem_Storage.Melee.Instances.hitmarker
local remotes: {[string] : RemoteEvent} = {
    Hit = ItemSystem_Storage.Melee.Remotes.Hit,
    ToggleSwingTrail = ItemSystem_Storage.Melee.Remotes.ToggleSwingTrail
}
local particles : {[string] : ParticleEmitter} = {
    blood = ItemSystem_Storage.Melee.Instances.Blood
}

local Item = require("../Superclasses/Item")
local HitboxManager = require("../Components/Shared/HitboxManager")
local ItemHUD = require("../Components/Shared/ItemHUD")
local ActionManager = require("../../ActionManagerSystem/ActionManager")
local StaminaManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.Stamina.StaminaManager)
local MeleeVMM = require("../Components/Melee/MeleeVMM")
local CrosshairGuiManager = require("../Components/Shared/CrosshairManager")
local CameraShaker = require(ReplicatedStorage.Packages.CameraShaker)
local currentCamera = workspace.CurrentCamera
local camShake = CameraShaker.new(Enum.RenderPriority.Last.Value, function(shakeCF)
    currentCamera.CFrame *= shakeCF
end)
camShake:Start()

export type MeleeObject = Item.ItemType & {
    damage : number,
    staminaCost: number,
    swingSpeed : number,
    HitboxManager : HitboxManager.HitboxManager,
    trail : Trail,
    staminaObject: StaminaManager.StaminaObject
}

local Melee =  {}

function Melee.new(tool : Tool, humanoid : Humanoid) : MeleeObject
    local self = Item.new(tool, humanoid)
    self.damage = 50
    self.staminaCost = 10
    self.swingSpeed = 1
    self.HitboxManager = HitboxManager.new(tool)
    self.trail = tool:FindFirstChildWhichIsA("Trail", true)
    self.staminaObject = StaminaManager.waitForStaminaObject(humanoid.Parent:: Model)

    self.actionNames.swing = "Swing" 
    Melee.toggleSwingTrail(self, false)

    Melee.initialize(self)

    return self
end

local function toggleSwingBind(self : MeleeObject, toggle : boolean)
    if toggle then
        ActionManager.bindAction(
            self.actionNames.swing, 
            function(): (() -> (), () -> (), () -> ())  

                StaminaManager.addBoundAction(self.staminaObject, self.actionNames.swing, self.staminaCost)

                local function onActivated()
                    StaminaManager.changeStaminaBarBy(self.staminaObject, self.staminaCost)
                    Melee.swing(self)
                end

                local function onDeactivated()
                    
                end

                local function onUnbind()
                    StaminaManager.removeBoundAction(self.staminaObject, self.actionNames.swing)
                end

                return onActivated, onDeactivated, onUnbind
            end, 
            Enum.UserInputType.MouseButton1,
            Enum.KeyCode.ButtonR2, 
            3, 
            nil, 
            self.animManager.animationTracks[self.tool.Name].swing.Length, 
            "rbxassetid://115384682565092")
    else
        ActionManager.unbindAction(self.actionNames.swing)
    end
end

function Melee.initialize(self : MeleeObject)
    Item.initialize(
        self,
        function()  --onEquipping
        end, 
        function() --onEquipped
            toggleSwingBind(self, true)
        end,
        function() --onUnequipping
            toggleSwingBind(self, false) 
        end,
        function() --onUnequipped()
        end, 
        function() --onDropping()
            toggleSwingBind(self, false)
        end,
        function() --onDropped()
        end
    )
    MeleeVMM.ConnectTrailsTransparencyUpdater(self.ViewmodelManager, self.tool)
    local swingTrack = self.animManager.animationTracks[self.tool.Name].swing
    swingTrack:GetMarkerReachedSignal("swing"):Connect(function(status : "start" | "end")
        if self.State ~= "Unequipped" then
            if status == "start" then
                self.soundManager.playSound("Server", self.soundManager.Sounds[self.tool.Name].swing :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0)
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
        -- warn("hit ", character.Name)
        local impactSounds = self.soundManager.Sounds[self.tool.Name].impact :: {[string] : Sound}
        local fleshSound = impactSounds.flesh
        self.soundManager.playSound("Server", fleshSound, self.tool:FindFirstChild("BodyAttach", true), 0)
        CrosshairGuiManager.showHitmarker(self.crosshairGuiObject, function()  
            self.soundManager.playSound("Client", hitmarkerSound, self.tool:FindFirstChild("BodyAttach", true), 0)
        end)
        camShake:ShakeOnce(3, 5, 0.2, 0.2)
        remotes.Hit:FireServer(humanoid, self.damage, particles.blood, raycastResult.Position, raycastResult.Normal)
    end)
    --The bound action below is for testing purposes; to demonstrate how a faster swing animation somehow inadvertently increases the range
    -- ContextActionService:BindAction("ChangeSwingSpeed", function(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject): Enum.ContextActionResult?  
    --     if inputState == Enum.UserInputState.Begin then
    --         local newSpeed = if self.swingSpeed == 2 then 0.5 else 2
    --         self.swingSpeed = newSpeed
    --         warn("Changing swingSpeed to ", newSpeed)
    --     end
    --     return Enum.ContextActionResult.Sink
    -- end, true, Enum.KeyCode.P)

end

function Melee.swing(self : MeleeObject)
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

function Melee.toggleSwingTrail(self : MeleeObject, toggle : boolean)
    remotes.ToggleSwingTrail:FireServer(self.trail, toggle)
    local vmToolTrail : Trail? = self.ViewmodelManager.ToolToVMToolMapping[self.tool]:FindFirstChildWhichIsA("Trail", true)
    if vmToolTrail then
        vmToolTrail.Enabled = toggle
    end
end

-- function Melee.Destroy

return Melee