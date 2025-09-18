local player = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InventoryManager = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.InventoryManager)
local ItemInstantiator = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.PlayerScripts.ItemInstantiator)
local References_ItemSystem = require(ReplicatedStorage.RojoManaged_RS.ItemSystem_ScriptStorage.References_ItemSystem)

local function initInventorySystem(character: Model)
    local InventoryObj = InventoryManager.new(
        function(tool: Tool) -- onToolAdded
            local itemInstance, destroyFunction = ItemInstantiator.instantiateTool(tool) 
            if itemInstance == nil then
                warn("Item Instance returned nil")
                return
            else
                -- warn(`Created new instance of {tool}`)
                ItemInstantiator.toolToDestroyInfoMap[itemInstance.tool] = {
                    itemInstance = itemInstance,
                    destroyFunction = destroyFunction
                } 
            end
        end,
        function(tool: Tool) -- onToolRemoved
            local destroyInfo = ItemInstantiator.toolToDestroyInfoMap[tool]
            if destroyInfo then
                task.defer(function()
                    if destroyInfo.itemInstance and destroyInfo.itemInstance.tool then -- in the case of stackables being destroyed when within inventory do to merges, item info can be destroyed
                        -- print(`Destroying Item Object for {destroyInfo.itemInstance.tool}`)
                        destroyInfo.destroyFunction(destroyInfo.itemInstance)
                        ItemInstantiator.toolToDestroyInfoMap[tool] = nil
                    end
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

ItemInstantiator.initToolPrompts()

local initialCharacter = player.Character
if initialCharacter then
    References_ItemSystem.update(initialCharacter)
    initInventorySystem(initialCharacter)
end

player.CharacterAdded:Connect(function(character: Model)  
    References_ItemSystem.update(character)
    initInventorySystem(character)
end)