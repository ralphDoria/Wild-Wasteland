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
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if BodyAttach and hrp then
                   tool.Parent = workspace
                   BodyAttach.CFrame = hrp.CFrame * CFrame.new(0, 0, -3)
                else
                    warn("Can't drop tool: Tool BodyAttach or character HumanoidRootPart is nil")
                    return
                end
            else
                warn("Can't drop tool: character is nil")
                return
            end
        else
            tool.Parent = workspace
        end
        OnHitFloor(tool)
    end)
    remotes.RequestPickUpTool.OnServerInvoke = function(player: Player, tool: Tool)
        local character = player.Character
        local bodyAttach = tool:FindFirstChild("BodyAttach", true)
        if not character or not bodyAttach then
            warn("[RequestPickUpTool Denied]: character or bodyattach doesn't exist")
            return
        end
        if not character.PrimaryPart then
            warn("[RequestPickUpTool Denied]: character has no PrimaryPart")
            return false
        end
        local MAX_PICKUP_RANGE = 5
        local distance = (character.PrimaryPart.Position - bodyAttach.Position).Magnitude
        local isWithinRange: boolean = distance < MAX_PICKUP_RANGE
        if not isWithinRange then
            warn("[RequestPickUpTool Denied]: failed range check", distance)
            return false
        end
        local isInValidParent: boolean? = tool:FindFirstAncestorOfClass("Workspace") and (tool.Parent and not tool.Parent:FindFirstChildOfClass("Humanoid"))
        if not isInValidParent then
            warn("[RequestPickUpTool Denied]: failed parent check")
            return false
        end

        PlaySoundUtil(pickUp, bodyAttach.Position) 
        tool.Parent = player.Backpack
        return true
    end
    --more to add later
end
