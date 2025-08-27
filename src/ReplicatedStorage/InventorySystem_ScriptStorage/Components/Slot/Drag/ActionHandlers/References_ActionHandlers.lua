local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Main inventory references
local ItemSystem_Storage = ReplicatedStorage:FindFirstChild("ItemSystem_Storage", true)

-- Bindables
local bindables = {
    DropToolBindable = ItemSystem_Storage.Shared.Bindables.DropToolBindable,
    ImmediateUnequip = ItemSystem_Storage.Shared.Bindables.ImmediateUnequip,
}

-- Inventory script storage path
local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage

-- System modules
local ToolStateMachine = require(InventoryScriptStorage.Components.ToolStateMachine.Main_ToolStateMachine)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)
local DiegeticErrorMessagingManager = require(ReplicatedStorage.RojoManaged_RS.DiegeticErrorMessagingManager)
local EmptySlotFinder = require(InventoryScriptStorage.Components.Slot.EmptySlotFinder)
local SlotRegistry = require(InventoryScriptStorage.Components.Slot.SlotRegistry)

-- TweenService reference
local TweenService = game:GetService("TweenService")

return {
    -- Main references
    ReplicatedStorage = ReplicatedStorage,
    InventoryScriptStorage = InventoryScriptStorage,
    
    -- Bindables
    bindables = bindables,
    
    -- System modules
    ToolStateMachine = ToolStateMachine,
    LootActions = LootActions,
    DiegeticErrorMessagingManager = DiegeticErrorMessagingManager,
    EmptySlotFinder = EmptySlotFinder,
    SlotRegistry = SlotRegistry,
    
    -- Services
    TweenService = TweenService,
}
