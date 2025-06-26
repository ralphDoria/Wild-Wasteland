local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local handleTaggedInstances = require(RS.RojoManaged_RS.Utility.handleTaggedInstances)
local TAGS_LOOT = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.TAGS_LOOT)

local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local LootGuiManager = require(InventoryScriptStorage.LootingSection.Components.LootGuiManager)
local initializeClientSideStandardLootable = require(InventoryScriptStorage.LootingSection.Components.initializeClientSideStandardLootable)

local LootingSection = {}

function LootingSection.init()

    LootGuiManager.init()

    local connections = handleTaggedInstances(TAGS_LOOT.STANDARD_CONTAINER, 
        function(taggedInstance: Model | Tool) 
            if taggedInstance:HasTag("StorageWearable") then
                -- will be initialized within StorageWearable's code
                return
            end
            initializeClientSideStandardLootable(taggedInstance)
        end,
        function(taggedInstance: Instance)  

        end
    )
end

function LootingSection.ResizeGui()
    LootGuiManager.ResizeGui()
end

return LootingSection