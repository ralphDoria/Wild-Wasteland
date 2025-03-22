local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage")
local rev_SpawnTool : RemoteEvent = ToolSystem_Storage:FindFirstChild("SpawnTool", true)
local source = ReplicatedStorage:FindFirstChild("ToolCatalog", true)
local Players = game:GetService("Players")

local function foo(toolName : string, parent : Instance)
    local folder : Folder? = source[toolName]
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
        task.wait(1)
        foo("Barbed Bat", player.Backpack)
        task.wait(1)
        foo("Barbed Bat", player.Backpack)
    end)
end)
