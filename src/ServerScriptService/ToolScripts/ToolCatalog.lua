local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ToolModels = ServerStorage:FindFirstChild("ToolModels", true)
local ToolScripts = ServerScriptService:FindFirstChild("ToolScripts", true)

local ToolCatalog = {}

local function addTool(toolName : String, toolType : String, description : String, price : number)
    if ToolModels:FindFirstChild(toolName) and ToolScripts:FindFirstChild(toolName) then
        ToolCatalog[toolName] = {
            ToolObject = ToolModels[toolName],
            Scripts = ToolScripts[toolName].Scripts,
            Type = toolType,
            Description = description,
            Price = price
        }   
        --print(toolName .. " was successfully added to the ToolCatalog")
    else
        warn(toolName .. " could not be added to ToolCatalog: missing a model or a script / tool name is invalid")
    end
end

--Initialize Tool Catalog
--print("initializing ToolCatalog")
for _, child in ToolModels:GetChildren() do
    if child:IsA("Tool") then
        addTool(child.Name, child:GetAttribute("Type"), child:GetAttribute("Description"), child:GetAttribute("Price"))
    end
end

return ToolCatalog