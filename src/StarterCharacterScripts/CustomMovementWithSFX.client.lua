--[[
    *A separate script will deal with updating the Stamina HUD Gui based on a couple things

    -w/ SFX means this script will also handle footstep sounds

    -play animation based on player speed

    !!!!
    this script is currently hecka buggy & needs to be fixed later
]]

--Sprint

--Crouch

local player = game.Players.LocalPlayer
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local animator = humanoid:WaitForChild("Animator")
local UIS = game:GetService("UserInputService")
local PlayerGui = player:WaitForChild("PlayerGui")
local CharacterStatusGui = PlayerGui:WaitForChild("CharacterStatusGui")

local SPRINT_KEY = Enum.KeyCode.LeftShift

--for sprinting
local defaultSpeed = 8
local sprintSpeed = 16
local MAXSTAMINA = 100
local currentStamina = MAXSTAMINA
local isRunning = false
local staminaBar = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaFrame")
local staminaLabel = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaLabel")
local staminaRegen = false

local function createAnimObject(animID)
    local newAnim = Instance.new("Animation")
    newAnim.AnimationId = animID
    return newAnim
end

local function createAnimTrack(animObject)
    return animator:LoadAnimation(animObject)
end

local animTracks = {
    sprint = createAnimTrack(createAnimObject("rbxassetid://17809481242")),
    walk = createAnimTrack(createAnimObject("rbxassetid://17833281861"))
}


local isMoving

humanoid.Running:Connect(function(speed)
    print(speed)
    if speed > sprintSpeed - 1 then
        animTracks.sprint:Play()
        animTracks.walk:Stop()
    elseif speed > 0.01 then
        animTracks.sprint:Stop()
        animTracks.walk:Play()
    else
        animTracks.sprint:Stop()
        animTracks.walk:Stop()
    end
end)

local function onInputBegan(input)
    if input.KeyCode == SPRINT_KEY then
		humanoid.WalkSpeed = sprintSpeed
		isRunning = true
		staminaRegen = false
		while currentStamina > 0 and isRunning do
			currentStamina = math.clamp(currentStamina - 1, 0, MAXSTAMINA) --math.clamp ensures currentStamina doesn't go below 0
			staminaLabel.Text = "Stamina: ".. math.round(currentStamina/MAXSTAMINA*100) .. "%" --displays the percent of stamina remaining rounded to the nearest whole #
			staminaBar:TweenSize(UDim2.new(currentStamina/MAXSTAMINA, 0, 1, 0), "Out", "Linear", 0)
			task.wait()
			if currentStamina <= 0 then
				humanoid.WalkSpeed = defaultSpeed
			end
		end
	end
end

local function onInputEnded(input)
    if input.KeyCode == SPRINT_KEY then
		isRunning = false
		staminaRegen = true
		humanoid.WalkSpeed = defaultSpeed
		while currentStamina < MAXSTAMINA and not isRunning do
			currentStamina = math.clamp(currentStamina + 0.2, 0, MAXSTAMINA) --ensures # doesn't exceed maximum stamina w/ the uneven adding of fractions 
			staminaLabel.Text = "Stamina: ".. math.round(currentStamina/MAXSTAMINA*100) .. "%"
			if staminaRegen == false then
				break
			end
			staminaBar:TweenSize(UDim2.new(currentStamina/MAXSTAMINA,0,1,0), "Out", "Linear", 0)
			task.wait()
			if currentStamina == 0 then
				humanoid.WalkSpeed = defaultSpeed
			end
		end
	end
end

UIS.InputBegan:Connect(onInputBegan)
UIS.InputEnded:Connect(onInputEnded)
--end of sprint code; what I learned: printing is vital to catch logic errors, don't rely on system errors. It's good practice !!

