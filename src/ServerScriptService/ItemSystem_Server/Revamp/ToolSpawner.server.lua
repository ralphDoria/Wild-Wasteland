local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage")
local rev_SpawnTool : RemoteEvent = ItemSystem_Storage:FindFirstChild("SpawnTool", true)
local ToolCatalog = ReplicatedStorage:FindFirstChild("ToolCatalog", true)
local Players = game:GetService("Players")

local function foo(toolName : string, parent : Instance)
    local folder : Folder? = ToolCatalog[toolName]
    if folder == nil then
        warn(toolName .. " not found in ToolCatalog FOLDER")
    else
        local tool = folder:FindFirstChildOfClass("Tool")
        local newTool = tool:Clone()
        newTool.Parent = parent
    end
end

rev_SpawnTool.OnServerEvent:Connect(function(player : Player, toolName : string, parent : Instance)
    foo(toolName, parent)
end)

Players.PlayerAdded:Connect(function(player: Player)  
    player.CharacterAdded:Connect(function(character: Model)  
        -- foo("Healing Injection", player.Backpack)
        foo("Healing Injection", player.Backpack)
        foo("Barbed Bat", player.Backpack)
        foo("Bloxy Cola Caps", player.Backpack)
        foo("Bloxy Cola Caps", player.Backpack)
        -- foo("Healing Injection", player.Backpack)
        -- foo("Healing Injection", player.Backpack)
        foo("Backpack", player.Backpack)
        -- foo("NV Goggles", player.Backpack)
    end)
end)
