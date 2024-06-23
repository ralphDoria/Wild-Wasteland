local character = script:FindFirstAncestorWhichIsA("Model")
local player = game:GetService("Players"):GetPlayerFromCharacter(character)
local backpack = player:WaitForChild("Backpack")
local humanoid = character:FindFirstChild("Humanoid")
local hrp = character:FindFirstChild("HumanoidRootPart")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local detectDroppedToolHitFloor = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("DetectDroppedToolHitFloor"))

humanoid.Died:Connect(function()
    humanoid:UnequipTools()

    for _, tool in backpack:GetChildren() do
        tool.Parent = workspace
        detectDroppedToolHitFloor(tool)
        local bodyAttach = tool:FindFirstChild("BodyAttach")
        if bodyAttach then
            bodyAttach.CFrame = hrp.CFrame
        end
    end
end)