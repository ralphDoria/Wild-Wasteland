local ReplicatedStorage = game:GetService("ReplicatedStorage")
local bfn_serverSpawnTool = ReplicatedStorage.ItemSystem_Storage.Shared.Bindables.ServerSpawnTool:: BindableFunction
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
        return newTool
    end
end

-- NOTE: the client-facing `SpawnTool` RemoteEvent was removed (C1) — it cloned any catalog
-- tool into any client-chosen parent with zero validation. Server-side spawning goes through
-- the `ServerSpawnTool` BindableFunction below.

bfn_serverSpawnTool.OnInvoke = function(toolName : string, parent : Instance)
    return foo(toolName, parent)
end

Players.PlayerAdded:Connect(function(player: Player)  
    player.CharacterAdded:Connect(function(character: Model)  
        -- foo("Barbed Bat", player.Backpack)
        -- foo("Raider Axe", player.Backpack)
        -- foo("M9", player.Backpack)
        -- foo("Light Bullets", player.Backpack)
        -- foo("Backpack", player.Backpack)
        -- foo("Healing Injection", player.Backpack)
        -- foo("Healing Injection", player.Backpack)
        -- foo("AK47", player.Backpack)
        -- foo("NV Goggles", player.Backpack)
        -- foo("Bloxy Cola Caps", player.Backpack)
        -- foo("Bloxy Cola Caps", player.Backpack)
        -- foo("Bloxy Cola Caps", player.Backpack)
        -- foo("Bloxy Cola Caps", player.Backpack)
        -- foo("Healing Injection", player.Backpack)
        -- foo("Light Bullets", player.Backpack)
    end)
end)
