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

--vfx
local stamina_vfx = require("./Components/stamina_vfx")

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

local sfx_info: sfx_info = {
    ["Male"] = {
        sound = References.SoundService:FindFirstChild("MaleBreathing", true),
        timePositionMarkers = {
            0,
            -- 0.07,--exhale
            0.56, --inhale
            References.SoundService:FindFirstChild("MaleBreathing", true).TimeLength
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
            0.69, --inhale
            References.SoundService:FindFirstChild("MaleBreathing", true).TimeLength
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
    staminaDrainSpeed: number,
    staminaRegenSpeed: number,
    connections: {RBXScriptConnection},
    drainActive: boolean,
    fillActive: boolean,
    MAX_FILL_COOLDOWN: number,
    currentFillCooldown: number,
    aboveStartBreathingThreshold: boolean,
    _actionNameToMinimumStaminaMap: {[string]: number},
    trove: any
}

local StaminaManager = {}

local initializedCharacters: {[Model]: StaminaObject} = {}
StaminaManager.initializedCharacters = initializedCharacters
StaminaManager.JUMP_STAMINA_COST = 10
local staminaChangedEvent: BindableEvent = Instance.new("BindableEvent")
StaminaManager.staminaChanged = staminaChangedEvent.Event :: RBXScriptSignal

local proportionMarkers = {
    startBreathing = 0.5,
    fastestBreathing = 0
}

function StaminaManager.new(): StaminaObject
    assert(References.character, "VitalsSystem References.Character is nil, cannot intiialize new StaminaObject")
    local statGuiObject = References.StatGuiManager.new(References.VitalsGui:WaitForChild("Frame"):WaitForChild("Stamina"), "Stamina", Color3.fromRGB(0, 150, 255)) 
    local MAX_STAMINA = 100
    local MAX_FILL_COOLDOWN = 0.5
    local self = {
        _associatedCharacter = References.character,
        statGuiObject = statGuiObject,
        MAX_STAMINA = MAX_STAMINA,
        currentStamina = MAX_STAMINA,
        staminaDrainSpeed = 5,
        staminaRegenSpeed = 10,
        connections = {},
        drainActive = false,
        fillActive = false,
        MAX_FILL_COOLDOWN = MAX_FILL_COOLDOWN,
        currentFillCooldown = MAX_FILL_COOLDOWN,
        aboveStartBreathingThreshold = true,
        _actionNameToMinimumStaminaMap = {},
        trove = Trove.new()
    }
    --important stuff for functionality
    References.StatGuiManager.SetStatValue(statGuiObject, self.currentStamina/MAX_STAMINA)
    StaminaManager._init(self)
    StaminaManager.initializedCharacters[self._associatedCharacter] = self

    return self
end

function StaminaManager._init(self: StaminaObject)
    self.trove:Connect(RunService.RenderStepped, function(dt: number)
        if self.currentFillCooldown > 0 then
            self.currentFillCooldown = math.clamp(self.currentFillCooldown - dt, 0, self.MAX_FILL_COOLDOWN)
        else
            if self.currentStamina < self.MAX_STAMINA and not self.drainActive then
                if not self.fillActive then
                    StaminaManager.fillStaminaBar(self)
                end
            end
        end

        if self.drainActive and not self.fillActive then
            if 0 < self.currentStamina then
                -- Drain Stamina
                StaminaManager._setStaminaBar(self, math.clamp(self.currentStamina - self.staminaDrainSpeed*dt, 0, self.MAX_STAMINA))
                self.currentFillCooldown = self.MAX_FILL_COOLDOWN
            else
                self.drainActive = false
            end
        elseif self.fillActive and not self.drainActive then
            if self.currentFillCooldown == 0 then
                if self.currentStamina < self.MAX_STAMINA then
                    -- fill stamina
                    StaminaManager._setStaminaBar(self, math.clamp(self.currentStamina + self.staminaRegenSpeed*dt, 0, self.MAX_STAMINA))
                else
                    self.fillActive = false
                end
            end

        end

        --warn("drainActive", drainActive, "| fillActive", fillActive)
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
        local staminaProportion: number = math.round((newStamina/References.humanoid.MaxHealth) * 100)/100
        StaminaManager._updateBreathingSoundProperties(self, staminaProportion)
    end)
end

function StaminaManager.Destroy(self: StaminaObject)
    StaminaManager.initializedCharacters[self._associatedCharacter] = nil
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
        RunService:BindToRenderStep("GuiBreathingSync", 201, function(delta: number)
            local currentTimePosition = math.round(sound.TimePosition*100)/100 
            for i = 1, #markers - 1, 1 do
                if markers[i] <= currentTimePosition and currentTimePosition < markers[i + 1] then
                    local dynamicColorValue: Color3
                    local t0: number = markers[i]
                    local t1: number = markers[i + 1]
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
    self.currentStamina = value
    local proportion = self.currentStamina/self.MAX_STAMINA
    References.StatGuiManager.SetStatValue(self.statGuiObject, proportion)
    staminaChangedEvent:Fire(self.currentStamina, value)
end

function StaminaManager.getStamina(self: StaminaObject)
    return self.currentStamina
end

function StaminaManager.changeStaminaBarBy(self: StaminaObject, delta: number)
    if not self.drainActive then
        self.currentFillCooldown = self.MAX_FILL_COOLDOWN 
    end
    local newValue = self.currentStamina - delta
    StaminaManager._setStaminaBar(self, newValue)
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