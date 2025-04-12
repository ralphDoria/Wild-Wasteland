local Config = require("./Config")
local References = require("../../CharacterStatsGuiSystem_Client/Components/References")
local RunService = game:GetService("RunService")
local sounds: {[string]: Sound} = {
    maleBreathing = References.SoundService:FindFirstChild("MaleBreathing"),
    femaleBreathing = References.SoundService:FindFirstChild("FemaleBreathing")
}

local statGui: CanvasGroup = References.CharacterStatsGui.Frame.stamina
local statGuiObject = References.StatGuiManager.new(statGui, "Stamina", Color3.fromRGB(0, 150, 255))
local ActionManager = require(game:GetService("ReplicatedStorage").RojoManaged_RS.ActionManagerSystem.ActionManager)
local MAX_STAMINA = 100
local staminaDrainSpeed = 10
local staminaRegenSpeed = 10
local currentStamina = MAX_STAMINA
References.StatGuiManager.SetStatValue(statGuiObject, currentStamina/MAX_STAMINA)

local connections: {RBXScriptConnection} = {}
local drainActive = false
local fillActive = false
local MAX_FILL_COOLDOWN: number = 0.5
local currentFillCooldown: number = MAX_FILL_COOLDOWN

------------------------------------------------------------------------<<<MODULE SCRIPT>>>
local StaminaManager = {_initialized = false}

StaminaManager.JUMP_STAMINA_COST = MAX_STAMINA * 0.1

local staminaChangedEvent: BindableEvent = Instance.new("BindableEvent")
StaminaManager.staminaChanged = staminaChangedEvent.Event :: RBXScriptSignal

StaminaManager.changeStaminaEvent = Instance.new("BindableEvent")
StaminaManager.changeStamina = StaminaManager.changeStaminaEvent.Event :: RBXScriptSignal

local cachedStamina: number = MAX_STAMINA

local proportionMarkers = {
    startBreathing = 0.5,
    fastestBreathing = 0
}

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
            for actionName, staminaThreshold in StaminaManager._boundActions do
                if currentStamina > staminaThreshold then
                    ActionManager.toggleEnabled(actionName, true)
                else
                    ActionManager.forceToggle(actionName, false) 
                    ActionManager.toggleEnabled(actionName, false)
                end
            end
        end)
    )
    --Use this method if the other method of changing stamina (stop using getStamina) doesn't work
    --The purpose of this event is to use the currentStamina value from this thread
    table.insert(
        connections,
        StaminaManager.changeStamina:Connect(function(delta: number)  
            StaminaManager.changeStaminaBarBy(delta)
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