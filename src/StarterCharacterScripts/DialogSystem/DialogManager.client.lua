local CollectionService = game:GetService("CollectionService")
local TAG_DIALOG = "Dialog"

local player = game:GetService("Players").LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local dialogGui : ScreenGui = player.PlayerGui:WaitForChild("DialogGui" )
local name : TextLabel = dialogGui:FindFirstChild("Name", true)
local proximityPrompt : ProximityPrompt = dialogGui:FindFirstChildWhichIsA("ProximityPrompt", true)

local getDialogInfo = require(script.Parent:FindFirstChild("getDialogInfo", true))
local processDialogInfo = require(script.Parent:FindFirstChild("ProcessDialogInfo", true))

local playerDistanceChecker : RBXScriptConnection

character.Humanoid.Died:Connect(function()
    player:SetAttribute("CancelDialog", true)
end)

dialogGui.Enabled = false
name.Visible = false
for _, npc in CollectionService:GetTagged(TAG_DIALOG) do
    assert(npc:IsA("Model") and npc:FindFirstChild("Humanoid"), npc.Name .. " is not a character with a humanoid.")

    local prompt = proximityPrompt:Clone()

    prompt.ObjectText = ""
    prompt.Parent = npc:FindFirstChild("Torso")
    prompt.Triggered:Connect(function()
        playerDistanceChecker = game:GetService("RunService").RenderStepped:Connect(function()
            local distance = math.abs((character.Torso.Position - npc.Torso.Position).Magnitude)
            if distance > 10 then
                player:SetAttribute("CancelDialog", true)
            end
        end)
        
        local dialogInfo = require(getDialogInfo(npc.Name))
        if dialogInfo.known then
            name.Text = dialogInfo.Name
        else
            name.Text = ""
        end

        processDialogInfo(dialogInfo, nil, prompt)
    end)
end