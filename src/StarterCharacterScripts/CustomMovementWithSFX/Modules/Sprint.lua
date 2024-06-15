local player = game.Players.LocalPlayer --Because of this line, this module must be required in a LocalScript, else there will be an error.
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local PlayerGui = player:WaitForChild("PlayerGui")
local CharacterStatusGui = PlayerGui:WaitForChild("CharacterStatusGui")

local SPRINT_KEY = Enum.KeyCode.LeftShift
local defaultSpeed = game:GetService("StarterPlayer").CharacterWalkSpeed
local sprintSpeed = 16
local MAXSTAMINA = 100
local currentStamina = MAXSTAMINA
local minRequiredStamina = 15 --this is a percentage
local staminaBar = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaFrame")
local minRequiredStaminaBar = staminaBar:Clone()
minRequiredStaminaBar.Size = UDim2.new(1*(minRequiredStamina/100), 0, 1, 0)
minRequiredStaminaBar.ZIndex = 2
minRequiredStaminaBar.BackgroundColor3 = Color3.new(0, 0, 0)
minRequiredStaminaBar.BackgroundTransparency = 0.8
minRequiredStaminaBar.Parent = staminaBar.Parent
local staminaLabel = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaLabel")
local drainConnection
local fillConnection
local RunService = game:GetService("RunService")
local isMoving

local Sprint = {sprintSpeed = sprintSpeed, SPRINT_KEY = SPRINT_KEY}

function Sprint.sprintKeyDown()
	local isMoving = character.PrimaryPart.AssemblyLinearVelocity.Magnitude > 0.01
	if not isMoving then return end
	if not isMoving or currentStamina/MAXSTAMINA < minRequiredStamina/100 then return end
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

function Sprint.sprintKeyUp()
    humanoid.WalkSpeed = defaultSpeed
    --If the stamina bar is depleting, then stop it
    if drainConnection then
        drainConnection:Disconnect()
        drainConnection = nil
    end
    
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

return Sprint