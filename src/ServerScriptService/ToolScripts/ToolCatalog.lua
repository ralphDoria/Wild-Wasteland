local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ToolModels = ServerStorage:WaitForChild("ToolModels")
local ToolScripts = ServerScriptService:WaitForChild("RojoManaged_SSS"):WaitForChild("ToolScripts")

ToolCatalog = {}

local function addTool(toolName : String)
    if ToolModels:FindFirstChild(toolName) or ToolScripts:FindFirstChild(toolName) then
        ToolCatalog[toolName] = {
            Model = ToolModels:WaitForChild(toolName),
            Scripts = ToolScripts:WaitForChild(toolName):WaitForChild("Scripts")
        }   
        --print(toolName .. " was successfully added to the ToolCatalog")
    else
        warn(toolName .. " could not be added to ToolCatalog: missing a model or a script.")
    end
end

addTool("Raider Axe")

return ToolCatalog