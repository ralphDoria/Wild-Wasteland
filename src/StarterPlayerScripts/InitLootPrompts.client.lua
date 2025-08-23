local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local handleTaggedInstances = require(RS.RojoManaged_RS.Utility.handleTaggedInstances)
local TAGS_LOOT = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.LootingSection.Components.TAGS_LOOT)

local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local lootingSectionComponents = InventoryScriptStorage.LootingSection.Components
local initClientLootable = require(lootingSectionComponents.initClientLootable)
local initStorageWearbleLootable = require(lootingSectionComponents.initStorageWearableLootable)

handleTaggedInstances(TAGS_LOOT.STANDARD_LOOTABLE, 
    function(taggedInstance: Model | Tool) 

        if taggedInstance:HasTag("vmTool") then return end

        if taggedInstance:HasTag("StorageWearable") then
            initStorageWearbleLootable(taggedInstance:: Tool)
        else
            initClientLootable(taggedInstance)
        end
    end,
    function(taggedInstance: Instance)  

        if taggedInstance:HasTag("vmTool") then return end

        -- lootable cleanup function
    end
)

handleTaggedInstances(
    TAGS_LOOT.CORPSE_LOOTABLE, 
    function(taggedInstance: Instance)  
        -- taggedInstance should be the HumanoidRootPart of the character model, regardless of if it's a player or NPC

        warn(`creating loot prompt for {Players.LocalPlayer.Name}`)
        initClientLootable(taggedInstance:: Model)

        -- hiding loot prompt from own player when they die, but show it after they respawn so that they can loot their own body
        local character = taggedInstance.Parent:: Model
        local player: Player? = Players:GetPlayerFromCharacter(character)
        if player == Players.LocalPlayer then
            local hrp = character:WaitForChild("HumanoidRootPart")
            local prompt = hrp:FindFirstChildOfClass("ProximityPrompt")
            if prompt then
                -- hide prompt until the plaer respawns
                prompt.Enabled = false
                Players.LocalPlayer.CharacterAdded:Once(function()  
                    prompt.Enabled = true
                end)
            end
        end
    end, 
    function(taggedInstance: Instance)  
        -- lootable cleanup function
    end
)
