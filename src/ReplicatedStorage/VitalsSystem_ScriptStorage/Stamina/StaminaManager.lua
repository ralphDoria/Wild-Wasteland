local RS = game:GetService("ReplicatedStorage")
local References = require(RS.RojoManaged_RS.VitalsSystem_ScriptStorage.Data.References)
local RunService = game:GetService("RunService")

--important stuff for functionality
task.wait(1) --TODO find a more proper way of doing this, but for now will yield so that VitalsSystem can initialize first
local statGui: CanvasGroup = References.VitalsGui.Frame.Stamina
local statGuiObject = References.StatGuiManager.new(statGui, "Stamina", Color3.fromRGB(0, 150, 255))
local ActionManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ActionManagerSystem.ActionManager)
local MAX_STAMINA = 100
local staminaDrainSpeed = 5
local staminaRegenSpeed = 10
local currentStamina = MAX_STAMINA
References.StatGuiManager.SetStatValue(statGuiObject, currentStamina/MAX_STAMINA)
local connections: {RBXScriptConnection} = {}
local drainActive = false
local fillActive = false
local MAX_FILL_COOLDOWN: number = 0.5
local currentFillCooldown: number = MAX_FILL_COOLDOWN

--vfx
local stamina_vfx = require("./Components/stamina_vfx")

--sfx 
local SoundUtility = require("../SharedComponents/SoundUtility")
type foo = {[string]: {
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

local sfx_info: foo = {
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
local StaminaManager = {_initialized = false}

StaminaManager.JUMP_STAMINA_COST = MAX_STAMINA * 0.1

local staminaChangedEvent: BindableEvent = Instance.new("BindableEvent")
StaminaManager.staminaChanged = staminaChangedEvent.Event :: RBXScriptSignal

local cachedStamina: number = MAX_STAMINA

local proportionMarkers = {
    startBreathing = 0.5,
    fastestBreathing = 0
}

local function toggleGuiBreathingSync(toggle: boolean)
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
                    References.TweenService:Create(References.StatGuiManager.getCanvasGroup(statGuiObject), TweenInfo.new(0), {GroupColor3 = dynamicColorValue}):Play()
                    return
                end
            end
        end)
    else
        -- print("Playing tween from:", BrickColor.new(References.StatGuiManager.getCanvasGroup(statGuiObject).GroupColor3).Name)
        RunService:UnbindFromRenderStep("GuiBreathingSync")
        local ti = TweenInfo.new(3)
        References.TweenService:Create(References.StatGuiManager.getCanvasGroup(statGuiObject), ti, {GroupColor3 = Color3.new(1, 1, 1)}):Play()
    end
end

local aboveStartBreathingThreshold = true

local function updateBreathingSoundProperties(staminaProportion: number)
    local sound = sfx_info[chosenGenderIdentity].sound
    local minBreathingSpeed = sfx_info[chosenGenderIdentity].breathingSpeed.min
    local maxBreathingSpeed = sfx_info[chosenGenderIdentity].breathingSpeed.max
    local minBreathingVolume = sfx_info[chosenGenderIdentity].breathingVolume.min
    local maxBreathingVolume = sfx_info[chosenGenderIdentity].breathingVolume.max
    if staminaProportion > proportionMarkers.startBreathing then
        if aboveStartBreathingThreshold == false then
            -- warn("crossed above StartBreathing Threshold")
            aboveStartBreathingThreshold = true

            toggleGuiBreathingSync(false)
            SoundUtility.tweenSoundSpeed(sound, minBreathingSpeed, 1)
            SoundUtility.tweenSoundVolume(sound, 0, 3)
        end
    else
        if aboveStartBreathingThreshold == true then
            -- warn("crossed below StartBreathing Threshold")
            aboveStartBreathingThreshold = false
            toggleGuiBreathingSync(true)
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

function StaminaManager._setStaminaBar(value: number)
    currentStamina = value
    local proportion = currentStamina/MAX_STAMINA
    References.StatGuiManager.SetStatValue(statGuiObject, proportion)
end

function StaminaManager.getStamina()
    return currentStamina
end

function StaminaManager.changeStaminaBarBy(delta: number)
    if not drainActive then
        currentFillCooldown = MAX_FILL_COOLDOWN 
    end
    currentStamina = currentStamina - delta
    local proportion = currentStamina/MAX_STAMINA
    References.StatGuiManager.SetStatValue(statGuiObject, proportion)
end

function StaminaManager.drainStaminaBar()
    drainActive = true
    fillActive = false
end

function StaminaManager.fillStaminaBar()
    fillActive = true
    drainActive = false
end

local function disconnectAllConnections()
    if #connections ~= 0 then
        for _, v in connections do
            if v ~= nil then
                v:Disconnect()
                v = nil
            end
        end
    end
end

StaminaManager._boundActions = {}

function StaminaManager.addBoundAction(actionName: string, staminaThreshold: number)
    StaminaManager._boundActions[actionName] = staminaThreshold
end

function StaminaManager.removeBoundAction(actionName: string)
    StaminaManager._boundActions[actionName] = nil
end

function StaminaManager.initialize()
    if StaminaManager._initialized then
        warn("Already initialized")
        return
    end
    table.insert(
        connections,
        RunService.RenderStepped:Connect(function(dt: number)
            if currentFillCooldown > 0 then
                currentFillCooldown = math.clamp(currentFillCooldown - dt, 0, MAX_FILL_COOLDOWN)
            else
                if currentStamina < MAX_STAMINA and not drainActive then
                    if not fillActive then
                        StaminaManager.fillStaminaBar()
                    end
                end
            end

            if drainActive and not fillActive then
                if 0 < currentStamina then
                    -- Drain Stamina
                    StaminaManager._setStaminaBar(math.clamp(currentStamina - staminaDrainSpeed*dt, 0, MAX_STAMINA))
                    currentFillCooldown = MAX_FILL_COOLDOWN
                else
                    drainActive = false
                end
            elseif fillActive and not drainActive then
                if currentFillCooldown == 0 then
                    if currentStamina < MAX_STAMINA then
                        -- fill stamina
                        StaminaManager._setStaminaBar(math.clamp(currentStamina + staminaRegenSpeed*dt, 0, MAX_STAMINA))
                    else
                        fillActive = false
                    end
                end

            end

            if cachedStamina ~= currentStamina then
                staminaChangedEvent:Fire(cachedStamina, currentStamina)
                cachedStamina = currentStamina
            end
            --warn("drainActive", drainActive, "| fillActive", fillActive)
        end)
    )
    table.insert(
        connections,
        StaminaManager.staminaChanged:Connect(function(cachedStamina: number, currentStamina: number)  
            -- Disables certain actions based on its corresponding staminaThreshold
            for actionName, staminaThreshold in StaminaManager._boundActions do
                if currentStamina > staminaThreshold then
                    ActionManager.toggleEnabled(actionName, true)
                else
                    ActionManager.forceToggle(actionName, false) 
                    ActionManager.toggleEnabled(actionName, false)
                end
            end

            --
            local staminaProportion: number = math.round((currentStamina/References.humanoid.MaxHealth) * 100)/100
            updateBreathingSoundProperties(staminaProportion)
        end)
    )
    References.humanoid.Died:Once(function(...: any)  
        disconnectAllConnections()
        StaminaManager._initialized = false
    end)
    StaminaManager._initialized = true
end

StaminaManager.initialize()

return StaminaManager