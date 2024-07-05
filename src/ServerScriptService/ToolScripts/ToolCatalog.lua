local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ToolModels = ServerStorage:WaitForChild("ToolModels")
local ToolScripts = ServerScriptService:WaitForChild("RojoManaged_SSS"):WaitForChild("ToolScripts")

local ToolCatalog = {}

local function addTool(toolName : String, description : String)
    if ToolModels:FindFirstChild(toolName) or ToolScripts:FindFirstChild(toolName) then
        ToolCatalog[toolName] = {
            Model = ToolModels:WaitForChild(toolName),
            Scripts = ToolScripts:WaitForChild(toolName):WaitForChild("Scripts"),
            Description = ""
        }   
        --print(toolName .. " was successfully added to the ToolCatalog")
    else
        warn(toolName .. " could not be added to ToolCatalog: missing a model or a script.")
    end
end

addTool("Raider Axe", "An axe from the Joyful Viking from the land of rectangular prisms in the sky.")
addTool("Healing Injection", "An autoinjector that fills the bloodstream with healing medication.")
addTool("Beretta", "A semiautomatic, magazine fed, recoil operated, double action pistol, chambered for the 9mm cartridge.")
--addTool("Beretta", "Simple, but can get the job done.")

return ToolCatalog