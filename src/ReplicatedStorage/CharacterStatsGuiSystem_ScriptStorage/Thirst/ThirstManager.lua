local RS = game:GetService("ReplicatedStorage")
local CharacterStatsGuiSystem_Storage = RS:FindFirstChild("CharacterStatsGuiSystem_Storage", true)
local remotes: {[string]: RemoteEvent} = {
    hungerThirstDamage = CharacterStatsGuiSystem_Storage:FindFirstChild("hungerThirstDamage", true)
}
local References = require(RS.RojoManaged_RS.CharacterStatsGuiSystem_ScriptStorage.Data.References)
local statGui: CanvasGroup = References.CharacterStatsGui.Frame.thirst
local statGuiObject = References.StatGuiManager.new(statGui, "Thirst", Color3.fromRGB(198, 204, 19))
local ThirstManager = {}

local thirstSound = References.SoundService:FindFirstChild("Gulping Water Glottal Croaks Slurp Water 1 (SFX)", true)
local maxValue = 100
local currentvalue = maxValue

local Config = {
    speed = 1/3,
    increment = 1,
    damage = 1
}

local threshold = {
    0, 0.1, 0.25, 0.5, 1
}

local function findThresholdSection(currentSection: number, currentProportion: number): number?
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
local currentThresholdSection = findThresholdSection(1, currentvalue/maxValue)

function ThirstManager.initialize()
    local trove = References.Trove.new()

    trove:Connect(thresholdChanged, function(newThresholdSection)
        if newThresholdSection ~= #threshold then
            thirstSound:Play()
        end
    end)

    local isAffected = false

    trove:Add(
        task.spawn(function()
            while task.wait(1/Config.speed) do
                ------------------
                -- threholdChanged signal fire
                ------------------
                local potentiallyNewThresholdSection = findThresholdSection(currentThresholdSection, currentvalue/maxValue)
                if potentiallyNewThresholdSection ~= currentThresholdSection then
                    thresholdChangedEvent:Fire(potentiallyNewThresholdSection)
                    currentThresholdSection = potentiallyNewThresholdSection
                end

                ------------------
                -- decrement hunger or damage humanoid flow control
                ------------------
                if currentvalue > 0 then
                    if isAffected == true then
                        isAffected = false
                        remotes.hungerThirstDamage:FireServer(false, References.humanoid, Config.damage)
                    end
                    local newValue = currentvalue - Config.increment
                    local proportion = newValue/maxValue
                    References.StatGuiManager.SetStatValue(statGuiObject, proportion)
                    currentvalue = newValue
                else
                    if isAffected == false then
                        isAffected = true
                        remotes.hungerThirstDamage:FireServer(true, References.humanoid, Config.damage)
                    end
                end   
                
                ------------------
                -- dynamic color change of gui relative to value
                ------------------
                if currentThresholdSection < #threshold - 1 then
                    local alpha = math.clamp(
                        math.map(
                            currentvalue/maxValue, 0, threshold[#threshold - 1], 0, 1 
                        ),
                        0,
                        1
                    ) 
                    References.StatGuiManager.getCanvasGroup(statGuiObject).GroupColor3 = statGuiObject.color:Lerp(Color3.new(1, 1, 1), alpha)
                end
            end
        end)
    )

    References.humanoid.Died:Once(function()
        trove:Destroy()
    end)
end

return ThirstManager