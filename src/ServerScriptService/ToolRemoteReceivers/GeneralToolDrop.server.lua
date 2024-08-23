local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rev_generalToolDrop = ReplicatedStorage.Tools:FindFirstChild("GeneralToolDrop", true)
local detectDroppedToolHitFloor = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("DetectDroppedToolHitFloor"))

--[[
    A general tool drop occurrs when you drop any tool from the inventory gui (which means it doesn't neccessarily have to equipped, 
    so it's case is slightly different from an equipped tool drop)
]]

rev_generalToolDrop.OnServerEvent:Connect(function(player : Player, tool : Tool)
    local character = player.Character
    if character == nil then return end
    local bodyAttach = tool:FindFirstChild("BodyAttach")
    if bodyAttach == nil then
        warn("BodyAttach not found")
        return
    end


    --[[
    TODO: Drag drop works, except in the case that the tool is equipped. Reference "x" to drop for potential solutions.
    ]]
    local toolIsEquipped = tool.Parent == character
    if toolIsEquipped then
        character.Humanoid:UnequipTools()
        print("!!! unequipping tool")
    end
    repeat
        task.wait()
    until tool.Parent ~= character

    tool.Parent = game.Workspace
    bodyAttach.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    detectDroppedToolHitFloor(tool)
end)