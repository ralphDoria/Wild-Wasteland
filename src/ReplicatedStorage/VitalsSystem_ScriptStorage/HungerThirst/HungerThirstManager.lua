local RS = game:GetService("ReplicatedStorage")
local VitalsSystem_Storage = RS:FindFirstChild("VitalsSystem_Storage", true)
local remotes: {[string]: RemoteEvent} = {
    hungerThirstDamage = VitalsSystem_Storage:FindFirstChild("hungerThirstDamage", true)
}
local References = require(RS.RojoManaged_RS.VitalsSystem_ScriptStorage.Data.References)

local soundsTbl = {
    Thirst = References.SoundService:FindFirstChild("Gulping Water Glottal Croaks Slurp Water 1 (SFX)", true),
    Hunger = References.SoundService:FindFirstChild("StomachRumble", true)
}

local Config = {
    Thirst = {
        speed = 1/3,
        increment = 1,
        damage = 1
    },
    Hunger = {
        speed = 1/4,
        increment = 1,
        damage = 1
    }
}

local valueThresholds = {
    Thirst = {0, 0.1, 0.25, 0.5, 1},
    Hunger = {0, 0.1, 0.25, 0.5, 1}
}

local function findThresholdSection(option: "Thirst" | "Hunger", currentSection: number, currentProportion: number): number?
    local threshold = valueThresholds[option]
    ------------------
    -- two for loops because checking starting from currentSection to end and then 
    -- going back to beginning and checking to currentSection may be faster in most cases
    ------------------
    for i = currentSection, #threshold - 1, 1 do
        if threshold[i] <= currentProportion and currentProportion <= threshold[i+1] then
            return i
        end
    end

    if currentSection ~= 1 then
        for i = 1, currentSection - 1, 1 do
            if threshold[i] <= currentProportion and currentProportion <= threshold[i+1] then
                return i
            end
        end 
    end

    return nil
end

local thresholdChangedEvent: BindableEvent = Instance.new("BindableEvent")
local thresholdChanged: RBXScriptSignal = thresholdChangedEvent.Event

export type hungerThirstObject = {
    MAX_VALUE: number,
    currentValue: number,
    currentThresholdSection: number,
    statGuiObject: any,
    trove: any
}

local HungerThirstManager = {}

function HungerThirstManager.new(option: "Hunger" | "Thirst"): hungerThirstObject
    local statGuiObject = References.StatGuiManager.new(References.VitalsGui:WaitForChild("Frame"):WaitForChild(option), option, if option == "Thirst" then Color3.fromRGB(198, 204, 19) else Color3.fromRGB(255, 123, 0))
    local trove = References.Trove.new()
    local MAX_VALUE = 100
    local currentValue = MAX_VALUE
    local currentThresholdSection = findThresholdSection(option, 1, currentValue/MAX_VALUE)

    local self: hungerThirstObject = {
        MAX_VALUE = MAX_VALUE,
        currentValue = currentValue,
        currentThresholdSection = currentThresholdSection,
        statGuiObject = statGuiObject,
        trove = trove
    }

    local threshold = valueThresholds[option]

    local sound = soundsTbl[option]
    trove:Connect(thresholdChanged, function(newThresholdSection)
        if newThresholdSection ~= #threshold then
            sound:Play()
        end
    end)

    local isAffected = false

    trove:Add(
        task.spawn(function()
            while task.wait(1/Config[option].speed) do
                ------------------
                -- threholdChanged signal fire
                ------------------
                local potentiallyNewThresholdSection = findThresholdSection(option, currentThresholdSection, currentValue/MAX_VALUE)
                if potentiallyNewThresholdSection ~= currentThresholdSection then
                    thresholdChangedEvent:Fire(potentiallyNewThresholdSection)
                    currentThresholdSection = potentiallyNewThresholdSection
                end

                ------------------
                -- decrement hunger or damage humanoid flow control
                ------------------
                if currentValue > 0 then
                    if isAffected == true then
                        isAffected = false
                        remotes.hungerThirstDamage:FireServer(false, References.humanoid, Config[option].damage)
                    end
                    local newValue = currentValue - Config[option].increment
                    local proportion = newValue/MAX_VALUE
                    References.StatGuiManager.SetStatValue(statGuiObject, proportion)
                    currentValue = newValue
                else
                    if isAffected == false then
                        isAffected = true
                        remotes.hungerThirstDamage:FireServer(true, References.humanoid, Config[option].damage)
                    end
                end   
                
                ------------------
                -- dynamic color change of gui relative to value
                ------------------
                if currentThresholdSection < #threshold - 1 then
                    local alpha = math.clamp(
                        math.map(
                            currentValue/MAX_VALUE, 0, threshold[#threshold - 1], 0, 1 
                        ),
                        0,
                        1
                    ) 
                    References.StatGuiManager.getCanvasGroup(statGuiObject).GroupColor3 = statGuiObject.color:Lerp(Color3.new(1, 1, 1), alpha)
                end
            end
        end)
    )

    return self
end

function HungerThirstManager.Destroy(self: hungerThirstObject)
    self.trove:Destroy()
    References.StatGuiManager.Destroy(self.statGuiObject)
    table.clear(self)
end

return HungerThirstManager