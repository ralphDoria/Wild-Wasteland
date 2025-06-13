local SINGLE_HINGE_LOOTABLE = "SingleHingeLootable"
local DOUBLE_HINGE_LOOTABLE = "DoubleHingeLootable"
local CORPSE_LOOTABLE = "CorpseLootable"
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local LootingSystem = RS.RojoManaged_RS.LootingSystem_ScriptStorage
local Lootable = require(RS.RojoManaged_RS.LootingSystem_ScriptStorage.Lootable)
local remotes = {
    OpenLootable = RS.LootingSystem_Storage.Remotes.OpenLootable,
    CloseLootable = RS.LootingSystem_Storage.Remotes.CloseLootable
}

local function waitForPrimaryPart(model: Model, timeout: number?)
    timeout = timeout or 10 -- Default 10 second timeout
    local startTime = tick()
    
    repeat 
        wait()
    until model.PrimaryPart or (tick() - startTime) > timeout

    if model.PrimaryPart == nil then
        warn(`Primary part of {model} was not found before timeout of {timeout} seconds. Check the model properties to see if it was set.`)
    end
    
    return model.PrimaryPart
end

local TAGS = {
    ["SingleHingeLootable"] = require(RS.RojoManaged_RS.LootingSystem_ScriptStorage.LootableTypes.SingleHingeLootable),
    -- ["DoubleHingeLootable"] = require(RS.RojoManaged_RS.LootingSystem_ScriptStorage.LootableTypes.DoubleHingeLootable),
    -- ["CorpseLootable"] = require(RS.RojoManaged_RS.LootingSystem_ScriptStorage.LootableTypes.CorpseLootable),
}

local function handleTag(taggedInstance: Model, tag: string)
    warn(`Creating lootable of type: {tag}`)
    Lootable.new(taggedInstance, waitForPrimaryPart(taggedInstance),
        function() -- onOpen
            remotes.OpenLootable:FireServer(taggedInstance, tag)
        end,
        function()  -- onClose
            remotes.CloseLootable:FireServer(taggedInstance, tag)
        end
    )
end

for TAG, _ in TAGS do
    for _, taggedInstance in CollectionService:GetTagged(TAG) do
        handleTag(taggedInstance, TAG)
    end
    CollectionService:GetInstanceAddedSignal(TAG):Connect(function(taggedInstance)
        handleTag(taggedInstance, TAG)
    end)
end

