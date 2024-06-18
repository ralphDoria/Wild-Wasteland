local player = game.Players.LocalPlayer
local character = player.Character
local humanoid = character:WaitForChild("Humanoid")
local PlayerGui = player:WaitForChild("PlayerGui")
local CharacterStatusGui = PlayerGui:WaitForChild("CharacterStatusGui")

local CharacterSpeedInfo = require(script.Parent.CharacterSpeedInfo)

local MAX_STAMINA = 100
local JUMP_STAMINA_COST = MAX_STAMINA * 0.3
local SLIDE_STAMINA_COST
local currentStamina = MAX_STAMINA
local MIN_REQUIRED_STAMINA = 15 --this is a percentage
local staminaBar = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaFrame")
local minRequiredStaminaBar = staminaBar:Clone()
minRequiredStaminaBar.Size = UDim2.new(1*(MIN_REQUIRED_STAMINA/100), 0, 1, 0)
minRequiredStaminaBar.Name = "minimumRequiredStaminaForSprintBar"
minRequiredStaminaBar.ZIndex = 2
minRequiredStaminaBar.BackgroundColor3 = Color3.new(0, 0, 0)
minRequiredStaminaBar.BackgroundTransparency = 0.8
minRequiredStaminaBar.Parent = staminaBar.Parent
local insufficientStaminaForJumpBar = staminaBar:Clone()
insufficientStaminaForJumpBar.Size = UDim2.new(JUMP_STAMINA_COST/100, 0, 1, 0)
insufficientStaminaForJumpBar.Name = "insufficientStaminaForJumpIndicator"
insufficientStaminaForJumpBar.ZIndex = 3
insufficientStaminaForJumpBar.BackgroundColor3 = Color3.new(1, 0, 0)
insufficientStaminaForJumpBar.BackgroundTransparency = 1
insufficientStaminaForJumpBar.Parent = staminaBar.Parent
local staminaLabel = CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame"):WaitForChild("staminaLabel")
local drainConnection
local fillConnection
local RunService = game:GetService("RunService")

local StaminaManager = {
    MAX_STAMINA = MAX_STAMINA,
    MIN_REQUIRED_STAMINA = MIN_REQUIRED_STAMINA,
    JUMP_STAMINA_COST = JUMP_STAMINA_COST
}

function StaminaManager.getCurrentStamina()
    return currentStamina
end

function StaminaManager.updateStaminaBar(newStaminaValue : number)
    currentStamina = math.clamp(newStaminaValue, 0, MAX_STAMINA) --math.clamp ensures currentStamina doesn't go below 0
    staminaLabel.Text = "Stamina: ".. math.round(currentStamina/MAX_STAMINA*100) .. "%" --displays the percent of stamina remaining rounded to the nearest whole #
    staminaBar:TweenSize(UDim2.new(currentStamina/MAX_STAMINA, 0, 1, 0), "Out", "Linear", 0)
end

function StaminaManager.indicateInsufficientStaminaForJump()
    if insufficientStaminaForJumpBar.BackgroundTransparency == 1 then
        insufficientStaminaForJumpBar.BackgroundTransparency = 0.8
        task.wait(0.2)
        insufficientStaminaForJumpBar.BackgroundTransparency = 1
    end
end

function StaminaManager.indicateInsufficientStaminaForSprint()
    if minRequiredStaminaBar.BackgroundColor3 == Color3.new(0, 0, 0) then
        minRequiredStaminaBar.BackgroundColor3 = Color3.new(1, 0, 0)
        task.wait(0.2)
        minRequiredStaminaBar.BackgroundColor3 = Color3.new(0, 0, 0)
    end
end

function StaminaManager.drainStaminaBar()
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
                StaminaManager.updateStaminaBar(currentStamina - 10*dt)
            else
                --When the player reaches 0 stamina, the stamina bar will no longer deplete and the player will be set back to walking speed
                drainConnection:Disconnect()
                drainConnection = nil
                humanoid.WalkSpeed = CharacterSpeedInfo.walkSpeed
                if CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame").BackgroundColor3 == Color3.fromRGB(97, 0, 176) then
                    CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame").BackgroundColor3 = Color3.new(1, 0, 0)
                    task.wait(0.2)
                    CharacterStatusGui:WaitForChild("staminaDisplay"):WaitForChild("bgFrame").BackgroundColor3 = Color3.fromRGB(97, 0, 176)
                end
            end
        end)
    end
end

function StaminaManager.fillStaminaBar()
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
            if currentStamina >= JUMP_STAMINA_COST then
                humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
            end
            if currentStamina < MAX_STAMINA then
                StaminaManager.updateStaminaBar(currentStamina + 10*dt)
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

return StaminaManager