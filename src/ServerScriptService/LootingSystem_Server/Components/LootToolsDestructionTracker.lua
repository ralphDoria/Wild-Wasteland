local RS = game:GetService("ReplicatedStorage")
local LootingSystem_Storage = RS.LootingSystem_Storage 
local LootItemsHolding: Folder = LootingSystem_Storage.LootItemsHolding

local LootToolsDestructionTracker = {}
local ToolDestroyedBindable = Instance.new("BindableEvent"):: BindableEvent
LootToolsDestructionTracker.ToolDestroyed = ToolDestroyedBindable.Event:: RBXScriptSignal

LootToolsDestructionTracker.ToolToLootableInstanceMap = {}:: {[Tool]: Tool}

-- If the tool is destroyed while in a lootable
LootItemsHolding.ChildRemoved:Connect(function(child: Instance)  
    if child:IsA("Tool") and child.Parent == nil then
        local serverLootable = LootToolsDestructionTracker.ToolToLootableInstanceMap[child]
        if serverLootable then
            --found
            ToolDestroyedBindable:Fire(child, serverLootable)
            LootToolsDestructionTracker.ToolToLootableInstanceMap[child] = nil
        else
            error("Error: corresponding server lootable now found")
        end
    end
end)


return LootToolsDestructionTracker