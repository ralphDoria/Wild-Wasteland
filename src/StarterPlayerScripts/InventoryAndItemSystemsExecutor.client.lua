local player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.InventoryManager)
local instantiateTool: (Tool) -> () = require(ReplicatedStorage.RojoManaged_RS.ToolSystem_ScriptStorage.PlayerScripts.instantiateTool)

type itemsToDestroy = {
    [Tool]: {
        itemInstance: any,
        destroyFunction: (any) -> ()
    }
}
local itemstoDestroy: itemsToDestroy = {}

local function initInventorySystem(character: Model)
    local InventoryObj = InventoryManager.new(
        function(tool: Tool) -- onToolAdded
            local itemInstance, destroyFunction = instantiateTool(tool) 
            if itemInstance == nil then
                return
            else
                itemstoDestroy[itemInstance.tool] = {
                    itemInstance = itemInstance,
                    destroyFunction = destroyFunction
                } 
            end
        end,
        function(tool: Tool) -- onToolRemoved
            local destroyInfo = itemstoDestroy[tool]
            if destroyInfo then
                task.defer(function()
                    destroyInfo.destroyFunction(destroyInfo.itemInstance)
                    itemstoDestroy[tool] = nil
                end)
            else
                warn("Destroy info not found")
            end
        end
    )

    local humanoid = character:WaitForChild("Humanoid"):: Humanoid
    humanoid.Died:Once(function(...: any)  
        InventoryManager.Destroy(InventoryObj)        
    end)
end

local initialCharacter = player.Character
if initialCharacter then
    initInventorySystem(initialCharacter)
end

player.CharacterAdded:Connect(function(character: Model)  
    initInventorySystem(character)
end)