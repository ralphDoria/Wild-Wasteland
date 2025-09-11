local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)
local PlaySoundUtil = require(ReplicatedStorage:FindFirstChild("Utility", true).PlaySoundUtil)
local remotes = {
    PlaySound = ItemSystem_Storage.Shared.Remotes.PlaySound,
    ToggleToolCanCollide = ItemSystem_Storage.Shared.Remotes.ToggleToolCanCollide,
    DropTool = ItemSystem_Storage.Shared.Remotes.DropTool,
    RequestPickUpTool = ItemSystem_Storage.Shared.Remotes.RequestPickUpTool:: RemoteFunction
}
local pickUp : Sound = ItemSystem_Storage.Shared.Sounds.pickUp
local OnHitFloor = require("./OnHitFloor")

return function()
    remotes.PlaySound.OnServerEvent:Connect(function(player: Player, sound : Sound, soundParent : any, delayCorrection : number)  
        print(`Playing {sound}`)
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
                local BodyAttach = tool:FindFirstChild("BodyAttach", true)
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
    remotes.RequestPickUpTool.OnServerInvoke = function(player: Player, tool: Tool)
        local MAX_PICKUP_RANGE = 5
        local character = player.Character
        local bodyAttach = tool.PrimaryPart
        local isWithinRange: boolean = if character and bodyAttach and math.abs((character.PrimaryPart.Position - bodyAttach.Position).Magnitude) < MAX_PICKUP_RANGE then true else false
        local isInValidParent: boolean? = tool:FindFirstAncestorOfClass("Workspace") and (tool.Parent and not tool.Parent:FindFirstChildOfClass("Humanoid"))
        if isWithinRange and isInValidParent then
            local BodyAttach = tool.PrimaryPart :: BasePart
            PlaySoundUtil(pickUp, BodyAttach.Position) 
            tool.Parent = player.Backpack
            return true
        else
            warn("RequestPickUpTool denied due to failing range and/or parent checks")
            return false
        end
    end
    --more to add later
end
