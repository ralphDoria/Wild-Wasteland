local ReplicatedStorage = game:GetService("ReplicatedStorage")

local rev_generalToolDrop = ReplicatedStorage.Tools:FindFirstChild("GeneralToolDrop", true)
local rev_playSound = ReplicatedStorage.Tools.Shared:FindFirstChild("PlaySound", true)
local rev_dropTool = ReplicatedStorage.Tools.Shared:FindFirstChild("DropTool", true)

local nvgogglesRS = ReplicatedStorage.Tools.Wearable["Night Vision Goggles"]
local rev_wearAccessory : RemoteEvent = nvgogglesRS:FindFirstChild("wearAccessory", true)

local playSound = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("PlaySoundUtil"))
local detectDroppedToolHitFloor = require(ReplicatedStorage:WaitForChild("RojoManaged_RS"):WaitForChild("Utility"):WaitForChild("DetectDroppedToolHitFloor"))

rev_wearAccessory.OnServerEvent:Connect(function(player, character, accessory)
    accessory.Parent = character
    --[[
    local this : Accessory = accessory:Clone()
    accessory.Parent = character
    ]]
end)

rev_playSound.OnServerEvent:Connect(function(player: Player, soundObject : Sound, soundParent : BasePart, delayCorrection : number)
    if typeof(soundParent) == "Number" then
        print(soundParent)
    end
    playSound(soundObject, soundParent, delayCorrection)
end)

rev_dropTool.OnServerEvent:Connect(function(player: Player, tool : Tool)
    tool.Parent = game.Workspace
    detectDroppedToolHitFloor(tool)
end)

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

        --[[
        (The wait line below may just be a workaround & not a permanent solution in all cases)
        It's here to ensure that the tool's drop protocol is ran before the tool's scripts get disabled
        ]]
        task.wait(0.1)

    end
    tool.Parent = game.Workspace
    bodyAttach.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3)
    detectDroppedToolHitFloor(tool)
end)