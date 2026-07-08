--[[
    Stamina PREDICTION + VIEW (Tier 3 Batch V2). The authoritative stamina sim runs
    server-side in VitalsSystem_Server/VitalsService and replicates via the player's
    "Stamina" attribute at the server tick rate. This module:
    - runs the SAME pure math (VitalsSim.staminaStep) per RenderStepped as a smooth local
      prediction feeding the bar, the breathing SFX, and the ActionManager gating;
    - reconciles the prediction to the replicated attribute, snapping only when they
      diverge past VitalsConfig.Stamina.reconcileSnapTolerance;
    - keeps the old public surface (drain/fill/changeStaminaBarBy/bound actions) so
      Sprint/Melee/MovementActions callers are unchanged.
    All numbers come from Data/VitalsConfig — the client no longer owns any of them.
]]
-----
-- Services
-----
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.Data.References)
local RunService = game:GetService("RunService")
-----
-- Dependencies
-----
local ActionManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ActionManagerSystem.ActionManager)
local Trove = require(ReplicatedStorage.Packages.Trove)
local VitalsConfig = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.Data.VitalsConfig)
local VitalsSim = require(ReplicatedStorage.RojoManaged_RS.VitalsSystem_ScriptStorage.Sim.VitalsSim)

local staminaConfig = VitalsConfig.Stamina

--sfx
local SoundUtility = require("../SharedComponents/SoundUtility")
type sfx_info = {[string]: {
    sound: Sound,
    timePositionMarkers: {
        number
    },
    breathingSpeed: {
        min: number,
        max: number
    },
    breathingVolume: {
        min: number,
        max: number
    }
}}

-- NOTE: the tables hold only the section START markers. The final section's end is the
-- sound's TimeLength, read LIVE in the GuiBreathingSync render step — TimeLength is 0
-- until the audio asset loads, and baking it in here at require time froze that 0 forever
-- on slow-load sessions (the blue-ramp-then-snap-to-white pulse bug).
local sfx_info: sfx_info = {
    ["Male"] = {
        sound = References.SoundService:FindFirstChild("MaleBreathing", true),
        timePositionMarkers = {
            0,
            -- 0.07,--exhale
            0.56 --inhale
        },
        breathingSpeed = {
            min = 0.5,
            max = 1.3
        },
        breathingVolume = {
            min = 0.5,
            max = 3
        }
    },
    ["Female"] = {
        sound = References.SoundService:FindFirstChild("FemaleBreathing", true),
        timePositionMarkers = {
            0,
            -- 0.14, --exhale
            0.69 --inhale
        },
        breathingSpeed = {
            min = 0.5,
            max = 1.3
        },
        breathingVolume = {
            min = 0.2,
            max = 1
        }
    }
}
local default: "Male" = "Male"
local chosenGenderIdentity: "Male" | "Female" = default
------------------------------------------------------------------------<<<MODULE SCRIPT>>>
export type StaminaObject = {
    _associatedCharacter: Model,
    statGuiObject: any,
    MAX_STAMINA: number,
    currentStamina: number,
    cooldownRemaining: number,
    drainActive: boolean,
    fillActive: boolean,
    aboveStartBreathingThreshold: boolean,
    _guiBreathingSyncActive: boolean,
    _actionNameToMinimumStaminaMap: {[string]: number},
    trove: any
}

local StaminaManager = {}

local initializedCharacters: {[Model]: StaminaObject} = {}
StaminaManager.initializedCharacters = initializedCharacters
StaminaManager.JUMP_STAMINA_COST = staminaConfig.jumpCost
local staminaChangedEvent: BindableEvent = Instance.new("BindableEvent")
StaminaManager.staminaChanged = staminaChangedEvent.Event :: RBXScriptSignal

local proportionMarkers = {
    startBreathing = 0.5,
    fastestBreathing = 0
}

function StaminaManager.new(): StaminaObject
    assert(References.character, "VitalsSystem References.Character is nil, cannot initialize new StaminaObject")
    local statGuiObject = References.StatGuiManager.new(References.VitalsGui:WaitForChild("Frame"):WaitForChild("Stamina"), "Stamina", Color3.fromRGB(0, 150, 255))
    local self = {
        _associatedCharacter = References.character,
        statGuiObject = statGuiObject,
        MAX_STAMINA = staminaConfig.max,
        currentStamina = staminaConfig.max,
        cooldownRemaining = 0,
        drainActive = false,
        fillActive = false,
        aboveStartBreathingThreshold = true,
        _guiBreathingSyncActive = false,
        _actionNameToMinimumStaminaMap = {},
        trove = Trove.new()
    }
    --important stuff for functionality
    References.StatGuiManager.SetStatValue(statGuiObject, self.currentStamina/self.MAX_STAMINA)
    StaminaManager._init(self)
    StaminaManager.initializedCharacters[self._associatedCharacter] = self

    return self
end

function StaminaManager._init(self: StaminaObject)
    -- Local prediction: the exact same pure step the server runs, at render rate.
    self.trove:Connect(RunService.RenderStepped, function(dt: number)
        local result = VitalsSim.staminaStep(
            self.currentStamina,
            self.cooldownRemaining,
            staminaConfig,
            dt,
            self.drainActive
        )
        self.cooldownRemaining = result.cooldownRemaining
        if result.stamina ~= self.currentStamina then
            StaminaManager._setStaminaBar(self, result.stamina)
        end
    end)

    -- Reconciliation: snap the prediction to the replicated authoritative value only
    -- when they diverge past the tolerance (they legitimately drift a few points
    -- between server ticks).
    self.trove:Connect(References.player:GetAttributeChangedSignal("Stamina"), function()
        local serverValue = References.player:GetAttribute("Stamina")
        if typeof(serverValue) ~= "number" then
            return
        end
        local reconciled = VitalsSim.reconcile(self.currentStamina, serverValue, staminaConfig.reconcileSnapTolerance)
        if reconciled ~= self.currentStamina then
            StaminaManager._setStaminaBar(self, reconciled)
        end
    end)

    self.trove:Connect(StaminaManager.staminaChanged, function(oldStamina: number, newStamina: number)
        -- Disables certain actions based on its corresponding staminaThreshold
        for actionName, staminaThreshold in self._actionNameToMinimumStaminaMap do
            if newStamina > staminaThreshold then
                ActionManager.toggleEnabled(actionName, true)
            else
                ActionManager.forceToggle(actionName, false)
                ActionManager.toggleEnabled(actionName, false)
            end
        end

        --
        local staminaProportion: number = math.round((newStamina/self.MAX_STAMINA) * 100)/100
        StaminaManager._updateBreathingSoundProperties(self, staminaProportion)
    end)
end

function StaminaManager.Destroy(self: StaminaObject)
    StaminaManager.initializedCharacters[self._associatedCharacter] = nil
    -- The render-step binding is a GLOBAL name the trove doesn't own. Dying while the
    -- breathing sync is active (stamina < 50%) would otherwise leak the binding — it
    -- keeps tweening the destroyed gui, and the next life's bind of the same name throws.
    if self._guiBreathingSyncActive then
        self._guiBreathingSyncActive = false
        RunService:UnbindFromRenderStep("GuiBreathingSync")
    end
    self.trove:Destroy()
    table.clear(self)
end

function StaminaManager.waitForStaminaObject(character: Model): StaminaObject
    if StaminaManager.initializedCharacters[character] then
        return StaminaManager.initializedCharacters[character]
    else
        repeat
            task.wait()
        until StaminaManager.initializedCharacters[character]
        return StaminaManager.initializedCharacters[character]
    end
end

function StaminaManager._toggleGuiBreathingSync(self: StaminaObject, toggle: boolean)
    local soundInfo = sfx_info[chosenGenderIdentity]
    local sound: Sound = soundInfo.sound
    local markers: {number} = soundInfo.timePositionMarkers
    local white = Color3.fromRGB(255, 255, 255) -- White
    local blue = Color3.fromRGB(0, 150, 255) -- Blueish

    -- local currentSectionIndex = 1

    local fadeOutTween: Tween?

    if toggle then
        self._guiBreathingSyncActive = true
        RunService:BindToRenderStep("GuiBreathingSync", 201, function(delta: number)
            -- Read TimeLength live: it stays 0 until the audio asset has loaded, so it
            -- must never be captured ahead of time. Until it's ready, skip the frame
            -- (the color just holds) — the pulse self-heals the moment the asset loads.
            local timeLength = sound.TimeLength
            if timeLength <= 0 then
                return
            end
            local currentTimePosition = math.round(sound.TimePosition*100)/100
            for i = 1, #markers, 1 do
                local t0: number = markers[i]
                local t1: number = markers[i + 1] or timeLength -- last section ends at the live TimeLength
                if t0 <= currentTimePosition and currentTimePosition < t1 then
                    local dynamicColorValue: Color3
                    local a: number = (currentTimePosition - t0) / (t1 - t0)
                    if i == 1 then
                        dynamicColorValue = white:Lerp(blue, a)
                    elseif i == 2 then
                        dynamicColorValue = blue:Lerp(white, a)
                    end
                    References.TweenService:Create(References.StatGuiManager.getCanvasGroup(self.statGuiObject), TweenInfo.new(0), {GroupColor3 = dynamicColorValue}):Play()
                    return
                end
            end
        end)
    else
        -- print("Playing tween from:", BrickColor.new(References.StatGuiManager.getCanvasGroup(self.statGuiObject).GroupColor3).Name)
        self._guiBreathingSyncActive = false
        RunService:UnbindFromRenderStep("GuiBreathingSync")
        local ti = TweenInfo.new(3)
        References.TweenService:Create(References.StatGuiManager.getCanvasGroup(self.statGuiObject), ti, {GroupColor3 = Color3.new(1, 1, 1)}):Play()
    end
end


function StaminaManager._updateBreathingSoundProperties(self: StaminaObject, staminaProportion: number)
    local sound = sfx_info[chosenGenderIdentity].sound
    local minBreathingSpeed = sfx_info[chosenGenderIdentity].breathingSpeed.min
    local maxBreathingSpeed = sfx_info[chosenGenderIdentity].breathingSpeed.max
    local minBreathingVolume = sfx_info[chosenGenderIdentity].breathingVolume.min
    local maxBreathingVolume = sfx_info[chosenGenderIdentity].breathingVolume.max
    if staminaProportion > proportionMarkers.startBreathing then
        if self.aboveStartBreathingThreshold == false then
            -- warn("crossed above StartBreathing Threshold")
            self.aboveStartBreathingThreshold = true

            StaminaManager._toggleGuiBreathingSync(self, false)
            SoundUtility.tweenSoundSpeed(sound, minBreathingSpeed, 1)
            SoundUtility.tweenSoundVolume(sound, 0, 3)
        end
    else
        if self.aboveStartBreathingThreshold == true then
            -- warn("crossed below StartBreathing Threshold")
            self.aboveStartBreathingThreshold = false
            StaminaManager._toggleGuiBreathingSync(self, true)
        end

        local dynamicSpeed = math.clamp(
            math.map(
                staminaProportion,
                proportionMarkers.startBreathing, proportionMarkers.fastestBreathing,
                minBreathingSpeed, maxBreathingSpeed
            ),
            minBreathingSpeed,
            maxBreathingSpeed
        )
        local dynamicVolume = math.clamp(
            math.map(
                staminaProportion,
                proportionMarkers.startBreathing, proportionMarkers.fastestBreathing,
                minBreathingVolume, maxBreathingVolume
            ),
            minBreathingVolume,
            maxBreathingVolume
        )
        SoundUtility.tweenSoundSpeed(sound, dynamicSpeed, 0.5)
        SoundUtility.tweenSoundVolume(sound, dynamicVolume, 0.5)
    end
end

function StaminaManager._setStaminaBar(self: StaminaObject, value: number)
    local oldStamina = self.currentStamina
    self.currentStamina = value
    local proportion = self.currentStamina/self.MAX_STAMINA
    References.StatGuiManager.SetStatValue(self.statGuiObject, proportion)
    staminaChangedEvent:Fire(oldStamina, value)
end

function StaminaManager.getStamina(self: StaminaObject)
    return self.currentStamina
end

-- Discrete local cost (jump/melee swing) — prediction only; the server charges the
-- authoritative cost itself (StateChanged -> Jumping, or the Swing remote).
function StaminaManager.changeStaminaBarBy(self: StaminaObject, delta: number)
    self.cooldownRemaining = staminaConfig.regenCooldown
    StaminaManager._setStaminaBar(self, VitalsSim.applyStaminaCost(self.currentStamina, delta))
end

function StaminaManager.drainStaminaBar(self: StaminaObject)
    self.drainActive = true
    self.fillActive = false
end

function StaminaManager.fillStaminaBar(self: StaminaObject)
    self.fillActive = true
    self.drainActive = false
end

function StaminaManager.addBoundAction(self: StaminaObject, actionName: string, staminaThreshold: number)
    self._actionNameToMinimumStaminaMap[actionName] = staminaThreshold
end

function StaminaManager.removeBoundAction(self: StaminaObject, actionName: string)
    self._actionNameToMinimumStaminaMap[actionName] = nil
end

return StaminaManager
