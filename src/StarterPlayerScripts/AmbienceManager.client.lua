local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local function isDayTime()
    return Lighting.ClockTime > 6.2 and Lighting.ClockTime < 18
end
local isIndoor = false

--------------------------<<< Sounds >>>
local ambientSounds = {
    vault = SoundService:FindFirstChild("Facility Ambience 1 Alternate", true),
    desertWinds = SoundService:FindFirstChild("DesertWinds", true),
    calmWind = SoundService:FindFirstChild("Ambient wind", true),
    night = SoundService:FindFirstChild("Grasslands Ambience Night 2", true)
}
local currentAmbience : sound = SoundService:FindFirstChild("CurrentAmbience", true)

local function changeCurrentAmbienceTo(sound : Sound)
    currentAmbience.SoundId = sound.SoundId
    currentAmbience.Volume = sound.Volume
end

currentAmbience:Play()
currentAmbience.Looped = true

local zones : Folder = workspace.Zones

local Zone = require(game:GetService("ReplicatedStorage"):FindFirstChild("Zone", true))

local vaultInteriorZones = Zone.new(zones.vaultInterior)
vaultInteriorZones:relocate()
vaultInteriorZones.localPlayerEntered:Connect(function()
    isIndoor = true
    changeCurrentAmbienceTo(ambientSounds.vault)
end)

vaultInteriorZones.localPlayerExited:Connect(function()
    isIndoor = false
    if isDayTime() then
        changeCurrentAmbienceTo(ambientSounds.desertWinds)
    else
        changeCurrentAmbienceTo(ambientSounds.night)
    end
end)

--------------------------<<< Day/Night Cycle >>>


local timeAccumulated = Lighting.ClockTime
RunService.RenderStepped:Connect(function(dt)
    -- for speed cycle testing
    -- timeAccumulated += dt * 10
    -- print(timeAccumulated)
    -- timeAccumulated = if timeAccumulated > 23.9 then 0 else timeAccumulated
    Lighting.ClockTime = timeAccumulated --speed cycle for testing

    -- Lighting.ClockTime = (workspace:GetServerTimeNow() / 60) % 24 --Normal cycle

    if isIndoor == false then
        if isDayTime() then
            changeCurrentAmbienceTo(ambientSounds.calmWind)
        else
            changeCurrentAmbienceTo(ambientSounds.night)
        end
    end
end)

