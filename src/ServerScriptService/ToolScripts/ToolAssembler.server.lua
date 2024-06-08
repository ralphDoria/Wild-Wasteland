local CollectionService = game:GetService("CollectionService")
local COLLECTION_TAG = "Tool"
local ToolCatalog = require(script.Parent:WaitForChild("ToolCatalog"))

local function assembleTool(toolName : String, parent)
    --Exception Handler
    if ToolCatalog[toolName] == nil then
        warn(toolName .. " cannot be created: does not exist in ToolCatalog")
        return
    end

    --assmebling the tool
    local tool : Tool = ToolCatalog[toolName].Model:Clone()
    local scripts = ToolCatalog[toolName].Scripts:Clone()
    scripts.Parent = tool

    --enabling the scripts
    for _, file : Script in scripts:GetChildren() do
        if not file:IsA("ModuleScript") and not file.Enabled then
            file.Enabled = true
        end
    end

    --puts tool in specified parent
    tool.Parent = parent

    --print(toolName .. " was successfully created: " .. tool.ClassName)
end

assembleTool("Raider Axe", game:GetService("Players"):GetPlayerFromCharacter(game.Workspace:WaitForChild("Niletheus")):WaitForChild("Backpack"))

