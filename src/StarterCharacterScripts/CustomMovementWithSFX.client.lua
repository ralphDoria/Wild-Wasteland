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
local defaultSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed
local sprintSpeed = 16
local MAXSTAMINA = 100
local currentStamina = MAXSTAMINA
local staminaBar = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaFrame")
local staminaLabel = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaLabel")
local drainConnection
local fillConnection
local RunService = game:GetService("RunService")

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
animTracks.sprint.Priority = Enum.AnimationPriority.Movement
animTracks.walk.Priority = Enum.AnimationPriority.Movement

local isMoving

--This handles the animations. It plays/stops certain animation tracks when the humanoid is moving at a certain speed.
humanoid.Running:Connect(function(speed)
	for _, animTrack in animator:GetPlayingAnimationTracks() do
		--print(animTrack.Name)
	end
    if speed > (sprintSpeed - 1) then
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

local function onInputBegan(input, gameProcessed)
	if gameProcessed then return end
	local isMoving = character.PrimaryPart.AssemblyLinearVelocity.Magnitude > 0.01
	if not isMoving then return end
    if input.KeyCode == SPRINT_KEY then
		humanoid.WalkSpeed = sprintSpeed
		--If the stamina bar is regenerating, then stop it
		if fillConnection then
			fillConnection:Disconnect()
			fillConnection = nil
		end

		--drains the stamina bar
		if drainConnection == nil then
			drainConnection = RunService.RenderStepped:Connect(function(dt)
				--print(currentStamina .. "-drain")
				--while the player has more than 0 stamina, the player will be able to sprint, but their stamina bar will deplete
				if currentStamina > 0 then
					currentStamina = math.clamp(currentStamina - 10*dt, 0, MAXSTAMINA) --math.clamp ensures currentStamina doesn't go below 0
					staminaLabel.Text = "Stamina: ".. math.round(currentStamina/MAXSTAMINA*100) .. "%" --displays the percent of stamina remaining rounded to the nearest whole #
					staminaBar:TweenSize(UDim2.new(currentStamina/MAXSTAMINA, 0, 1, 0), "Out", "Linear", 0)
				else
					--When the player reaches 0 stamina, the stamina bar will no longer deplete and the player will be set back to walking speed
					drainConnection:Disconnect()
					drainConnection = nil
					humanoid.WalkSpeed = defaultSpeed
				end
			end)
		end
	end
end

local function onInputEnded(input, gameProcessed)
	if gameProcessed then return end
    if input.KeyCode == SPRINT_KEY then
		humanoid.WalkSpeed = defaultSpeed
		--If the stamina bar is depleting, then stop it
		if drainConnection then
			drainConnection:Disconnect()
			drainConnection = nil
		end

		task.wait(1)
		
		if fillConnection == nil then
			--Regenerates the stamina bar
			fillConnection = RunService.RenderStepped:Connect(function(dt)
				--print(currentStamina .. "-fill")
				--If the player's stamina is less than their stamina cap, then their stamina bar will regenerate
				if currentStamina < MAXSTAMINA then
					currentStamina = math.clamp(currentStamina + 10*dt, 0, MAXSTAMINA) --ensures # doesn't exceed maximum stamina w/ the uneven adding of fractions 
					staminaLabel.Text = "Stamina: ".. math.round(currentStamina/MAXSTAMINA*100) .. "%"
					staminaBar:TweenSize(UDim2.new(currentStamina/MAXSTAMINA,0,1,0), "Out", "Linear", 0)
				else
					--the stamina bar will stop regenerating once it's reached max stamina
					if fillConnection then
						fillConnection:Disconnect()
						fillConnection = nil
					end
				end
			end)
		end
		
	end
end

UIS.InputBegan:Connect(onInputBegan)
UIS.InputEnded:Connect(onInputEnded)
--end of sprint code; what I learned: printing is vital to catch logic errors, don't rely on system errors. It's good practice !!

