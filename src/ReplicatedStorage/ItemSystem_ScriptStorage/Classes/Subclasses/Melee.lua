--!strict
-- local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_ItemSystem = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)


local hitmarkerSound : Sound = References_ItemSystem.ItemSystem_Storage.Melee.Instances.hitmarker
local meleeRemotes = {
    Hit = References_ItemSystem.ItemSystem_Storage.Melee.Remotes.Hit:: RemoteEvent,
    Swing = References_ItemSystem.ItemSystem_Storage.Melee.Remotes.Swing:: RemoteEvent
}
local particles : {[string] : ParticleEmitter} = {
    blood = References_ItemSystem.ItemSystem_Storage.Melee.Instances.Blood
}

-- Parent Class
local Item = require("../Superclasses/Item")

-- Melee Item specific modules
local HitboxManager = require("../Components/Shared/HitboxManager")
local StaminaManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.Stamina.StaminaManager)
local VitalsConfig = require(game:GetService("ReplicatedStorage").RojoManaged_RS.VitalsSystem_ScriptStorage.Data.VitalsConfig)
local MeleeVMM = require("../Components/Melee/MeleeVMM")
local CameraShaker = require(ReplicatedStorage.Packages.CameraShaker)
local currentCamera = workspace.CurrentCamera
local camShake = CameraShaker.new(Enum.RenderPriority.Last.Value, function(shakeCF)
    currentCamera.CFrame *= shakeCF
end)
camShake:Start()
local impactEffect = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Classes.Components.Gun.Utility.Effects.impactEffect)
-- Single source of truth for weapon damage (server reads the same table and is authoritative; the
-- value the client sends with the Hit remote is ignored — BUGS.md C6).
local CombatStats = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.Data.CombatStats)
-- Placed build structures are melee-hittable (identified by their CollectionService tag);
-- their metal impact sound lives next to the panel template in the build storage folder.
local BuildConfig = require(ReplicatedStorage.RojoManaged_RS.BuildSystem_ScriptStorage.Data.BuildConfig)

export type MeleeObject = Item.ItemObject & {
    damage : number,
    staminaCost: number,
    swingSpeed : number,
    HitboxManager : HitboxManager.HitboxManager,
    trail : Trail,
    staminaObject: StaminaManager.StaminaObject,
    trailsTransparencyUpdater: RBXScriptConnection,
    -- Characters already hit during the current swing. The hitbox runs in PartMode
    -- (fires once per PART), so without this a swing across several limbs would hit
    -- the same character multiple times.
    _swingHitHumanoids: {[Humanoid]: boolean}
}

local Melee =  {}

function Melee.new(tool : Tool) : MeleeObject
    local self: MeleeObject = Item.new(tool):: MeleeObject
    self.damage = (CombatStats[tool.Name] and CombatStats[tool.Name].damage) or 50
    -- Client-side prediction of the cost; the server charges the same number from
    -- VitalsConfig on the Swing remote (Tier 3 Batch V2)
    self.staminaCost = VitalsConfig.Stamina.swingCost
    self.swingSpeed = 1
    self.HitboxManager = HitboxManager.new(tool, {References_ItemSystem.character, References_ItemSystem.viewmodelManagerObject.viewmodel})
    self._swingHitHumanoids = {}
    self.trail = tool:FindFirstChildWhichIsA("Trail", true):: Trail
    self.staminaObject = StaminaManager.waitForStaminaObject(References_ItemSystem.character)

    self.actionNames.swing = "Swing" 
    Melee.toggleSwingTrail(self, false)

    Melee.initialize(self)

    return self
end

local function toggleSwingBind(self : MeleeObject, toggle : boolean)
    if toggle then
        References_ItemSystem.ActionManager.bindAction(
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
            References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].swing.Length,
            "rbxassetid://115384682565092")
    else
        References_ItemSystem.ActionManager.unbindAction(self.actionNames.swing)
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
    self.trailsTransparencyUpdater = MeleeVMM.ConnectTrailsTransparencyUpdater(References_ItemSystem.viewmodelManagerObject, self.tool)
    local swingTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].swing
    self.trove:Connect(swingTrack:GetMarkerReachedSignal("swing"), function(status : "start" | "end")
        if self.State ~= "Unequipped" then
            if status == "start" then

                References_ItemSystem.remotes.PlaySound:FireServer(self.soundObjects.swing, self.bodyAttach, 0)
                table.clear(self._swingHitHumanoids)
                HitboxManager.HitStart(self.HitboxManager)
                Melee.toggleSwingTrail(self, true)
            elseif status == "end" then
                HitboxManager.HitStop(self.HitboxManager)
                Melee.toggleSwingTrail(self, false)
            end 
        end
    end)

    -- PartMode fires once per PART per swing with humanoid = nil; resolve the target
    -- ourselves so swings can hit BOTH characters and placed build structures.
    HitboxManager.ConnectOnHit(self.HitboxManager, function(hit: BasePart, _neverResolved: Humanoid?, raycastResult: RaycastResult)
        local model = hit:FindFirstAncestorOfClass("Model")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")

        if humanoid then
            -- One hit per CHARACTER per swing (PartMode dedupes per part, and a swing
            -- sweeps across several limbs of the same rig).
            if self._swingHitHumanoids[humanoid] then
                return
            end
            self._swingHitHumanoids[humanoid] = true

            References_ItemSystem.remotes.PlaySound:FireServer(self.soundObjects.impact.flesh, self.bodyAttach, 0)
            References_ItemSystem.CrosshairGuiManager.showHitmarker(References_ItemSystem.crosshairGuiObject, function()
                References_ItemSystem.remotes.PlaySound:FireServer(hitmarkerSound, self.bodyAttach, 0)
            end)
            camShake:ShakeOnce(3, 5, 0.2, 0.2)
            meleeRemotes.Hit:FireServer(humanoid, self.damage, particles.blood, raycastResult.Position, raycastResult.Normal)
            impactEffect(raycastResult.Position, raycastResult.Normal, true, nil, nil) -- this is replicated to other players via the remote event above
        elseif CollectionService:HasTag(hit, BuildConfig.structureTag) then
            -- Placed structure: same validated Hit remote, structure part as the target
            -- (the server routes it to BuildService.damageStructure; the damage value is
            -- ignored there just like for humanoids). PartMode already dedupes the part.
            local metalSound = ReplicatedStorage:FindFirstChild(BuildConfig.storageFolderName)
            local impactSound = metalSound and metalSound:FindFirstChild("hl2 metal impact")
            if impactSound then
                References_ItemSystem.remotes.PlaySound:FireServer(impactSound, self.bodyAttach, 0)
            end
            References_ItemSystem.CrosshairGuiManager.showHitmarker(References_ItemSystem.crosshairGuiObject, function()
                References_ItemSystem.remotes.PlaySound:FireServer(hitmarkerSound, self.bodyAttach, 0)
            end)
            camShake:ShakeOnce(3, 5, 0.2, 0.2)
            meleeRemotes.Hit:FireServer(hit, self.damage, particles.blood, raycastResult.Position, raycastResult.Normal)
            impactEffect(raycastResult.Position, raycastResult.Normal, false, nil, nil)
        end
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
        local swingTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].swing
        local vmSwingTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].swing
        local idleTrack = References_ItemSystem.animationManagerObject.animationTracks[self.tool.Name].idle
        local vmIdleTrack = References_ItemSystem.viewmodelManagerObject.toolAnimationManagerObject.animationTracks[self.tool.Name].idle
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
    meleeRemotes.Swing:FireServer(self.tool, self.trail, toggle)
    self.trail.Enabled = toggle -- this is replicated by the remote event above
    local vmToolTrail : Trail? = References_ItemSystem.viewmodelManagerObject.ToolToVMToolMapping[self.tool]:FindFirstChildWhichIsA("Trail", true)
    if vmToolTrail then
        vmToolTrail.Enabled = toggle
    end
end

function Melee.Destroy(self: MeleeObject)
    Item.Destroy(self, function()  
        self.trailsTransparencyUpdater:Disconnect()
        print("Destroying hitbox")
        HitboxManager.Destroy(self.HitboxManager)
    end)
end

return Melee