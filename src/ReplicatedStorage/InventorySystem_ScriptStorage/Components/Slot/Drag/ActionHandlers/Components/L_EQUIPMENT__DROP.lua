local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local References_ActionHandlers = require(script.Parent.Parent.References_ActionHandlers)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)

local function L_EQUIPMENT__DROP(lootScrollingSlotData: types_and_enums.SlotData)
    --WIP; MODELING OFF OF L_INVENOTRY__DROP    

    -- local lootTool: Tool? = lootScrollingSlotData.slotObject.tool
    -- References_ActionHandlers.LootActions.TrySlotInteraction(References_Inventory.LootableInstanceObjectValue.Value, {
    --     __type = "CorpseLootable",
    --     lootToolLayoutOrder = lootScrollingSlotData.slotObject._itself.LayoutOrder,
    --     lootTool = lootTool,
    --     substituteTool = nil
    -- }):andThen(function()
    --     task.wait() -- give time for item to instantiate because when a tool is dropped, it actually passed through the player's backpack first
    --     References_ActionHandlers.bindables.DropToolBindable:Fire(lootTool)
    -- end):catch(function(error)
    --     warn("Error", tostring(error))
    -- end)
end

return L_EQUIPMENT__DROP
