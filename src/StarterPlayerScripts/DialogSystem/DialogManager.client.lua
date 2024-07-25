local CollectionService = game:GetService("CollectionService")
local TAG_DIALOG = "Dialog"

local player = game:GetService("Players").LocalPlayer
local dialogGui : ScreenGui = player.PlayerGui:WaitForChild("DialogGui" )
local proximityPrompt : ProximityPrompt = dialogGui:FindFirstChildWhichIsA("ProximityPrompt", true)

local getDialogInfo = script.Parent:FindFirstChild("getDialogInfo", true)
local processDialogInfo = script.Parent:FindFirstChild("ProcessDialogInfo", true)

for _, character in CollectionService:GetTagged(TAG_DIALOG) do
    assert(character:IsA("Model") and character:FindFirstChild("Humanoid"), character.Name .. " is not a character with a humanoid.")
    local prompt = proximityPrompt:Clone()
    prompt.ObjectText = character.Name
    prompt.Parent = character:FindFirstChild("Torso")
    prompt.Triggered:Connect(function()
        prompt.Enabled = false
        processDialogInfo(getDialogInfo(character.Name)) --this should be a yielding function
        prompt.Enabled = true
    end)
end