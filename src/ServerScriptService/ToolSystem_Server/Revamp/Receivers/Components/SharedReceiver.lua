local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local PlaySoundUtil = require(ReplicatedStorage:FindFirstChild("Utility", true).PlaySoundUtil)
local remotes: {[string] : RemoteEvent} = {
    PlaySound = ToolSystem_Storage.Shared.Remotes.PlaySound,
    ToggleToolCanCollide = ToolSystem_Storage.Shared.Remotes.ToggleToolCanCollide,
    DropTool = ToolSystem_Storage.Shared.Remotes.DropTool,
    PickUpTool = ToolSystem_Storage.Shared.Remotes.PickUpTool
}
local pickUp : Sound = ToolSystem_Storage.Shared.Sounds.pickUp
local OnHitFloor = require("./OnHitFloor")

return function()
    remotes.PlaySound.OnServerEvent:Connect(function(player: Player, sound : Sound, soundParent : any, delayCorrection : number)  
        PlaySoundUtil(sound, soundParent, delayCorrection)
    end)
    remotes.ToggleToolCanCollide.OnServerEvent:Connect(function(player: Player, toolModel: Model | MeshPart, toggle: boolean)
        if toolModel:IsA("MeshPart") then
            toolModel.CanCollide = toggle
        elseif toolModel:IsA("Model") then
            for _, v in toolModel:GetDescendants() do
                if v:IsA("BasePart") then
                    v.CanCollide = toggle
                end
            end
        end
    end)
    remotes.DropTool.OnServerEvent:Connect(function(player: Player, tool: Tool)
        if tool:FindFirstAncestorOfClass("Workspace") == nil then
            local character = player.Character
            if character then
                local BodyAttach = tool:FindFirstChild("BodyAttach")
                if BodyAttach then
                   tool.Parent = workspace
                   BodyAttach.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -3) 
                else
                    error("Can't drop tool: Tool BodyAttach is nil")
                end
            else
                error("Can't drop tool: character is nil")
            end
        else
            tool.Parent = workspace
        end
        OnHitFloor(tool)
    end)
    remotes.PickUpTool.OnServerEvent:Connect(function(player: Player, tool: Tool)
        local BodyAttach = tool.PrimaryPart :: BasePart
        PlaySoundUtil(pickUp, BodyAttach.Position) 
        tool.Parent = player.Backpack
    end)
    --more to add later
end
