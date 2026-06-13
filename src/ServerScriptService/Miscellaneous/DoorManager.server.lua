--fix proximity prompt, make is so that you can use the RequiresLineOfSight property to prevent buggy thangs
--figure out how to do sound regions

local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local playSound = require(game:GetService("ReplicatedStorage"):WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))

local doorSFX = game:GetService("SoundService").SoundStorage:FindFirstChild("VaultDoor", true)
local vaultDoorOpenSound = doorSFX["Vault Sliding Door Open"]
local vaultDoorCloseSound = doorSFX["Vault Sliding Door Close"]

local TIME_TO_OPEN = 0.3 

for _, door in ipairs(CollectionService:GetTagged("doorModel")) do
    --don't have a debounce variable for interacting with ProximityPrompt, just disable & reenable ProximityPrompt
    
    local hingePart = door.PrimaryPart
    local isOpen = false
    local pp : ProximityPrompt = door:FindFirstChild("ProximityPrompt", true)
    local openSound : Sound = door:FindFirstChild("Door Open", true)
    local closeSound : Sound = door:FindFirstChild("Door Close", true)
    
    pp.Triggered:Connect(function(playerWhoTriggered: Player)
        
        pp.Enabled = false
        
        local soundToPlay : Sound = closeSound
        local rotation = 100
        
        if not isOpen then
            rotation = -rotation
            soundToPlay = openSound
        end

        
        local DoorTween = TweenService:Create(
            hingePart,
            TweenInfo.new(TIME_TO_OPEN, Enum.EasingStyle.Linear),
            {CFrame = hingePart.CFrame * CFrame.Angles(0, math.rad(rotation), 0)}
        )
        
        DoorTween:Play()
        soundToPlay:Play()
        isOpen = not isOpen --reverses the boolean, does NOT just set it to false
        
        DoorTween.Completed:Connect(function(playbackState : Enum.PlaybackState) 
            pp.Enabled = true
        end)

    end)
end

for _, vaultDoor in CollectionService:GetTagged("door_vault") do
    local pp : ProximityPrompt = vaultDoor.PrimaryPart.ProximityPrompt
    local upper = vaultDoor.upper
    local lower = vaultDoor.lower
    local transitionTime = 1
    local tweenInfo = TweenInfo.new(transitionTime, Enum.EasingStyle.Linear)
    local isOpen = false
    pp.Triggered:Connect(function()
        if not isOpen then
            isOpen = true
            pp.Enabled = false
            TweenService:Create(upper, tweenInfo, {CFrame = upper.CFrame * CFrame.new(0, 4.9, 0)}):Play()
            TweenService:Create(lower, tweenInfo, {CFrame = lower.CFrame * CFrame.new(0, 1.9, 0):Inverse()}):Play()
            playSound(vaultDoorOpenSound, pp.Parent, 0)
            task.wait(transitionTime)
            pp.ActionText = "Close"
            pp.Enabled = true
        else
            isOpen = false
            pp.Enabled = false
            TweenService:Create(upper, tweenInfo, {CFrame = upper.CFrame * CFrame.new(0, 4.9, 0):Inverse()}):Play()
            TweenService:Create(lower, tweenInfo, {CFrame = lower.CFrame * CFrame.new(0, 1.9, 0)}):Play()
            playSound(vaultDoorCloseSound, pp.Parent, 0)
            task.wait(transitionTime)
            pp.ActionText = "Open"
            pp.Enabled = true
        end  
    end)
end
    