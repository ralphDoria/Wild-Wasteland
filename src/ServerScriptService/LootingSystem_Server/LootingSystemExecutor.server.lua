local RS = game:GetService("ReplicatedStorage")
local TAGS = {
    ["SingleHingeLootable"] = require(RS.RojoManaged_RS.LootingSystem_ScriptStorage.LootableTypes.SingleHingeLootable),
    ["DoubleHingeLootable"] = require(RS.RojoManaged_RS.LootingSystem_ScriptStorage.LootableTypes.DoubleHingeLootable),
    ["CorpseLootable"] = require(RS.RojoManaged_RS.LootingSystem_ScriptStorage.LootableTypes.CorpseLootable),
}
local remotes = {
    OpenLootable = RS.LootingSystem_Storage.Remotes.OpenLootable,
    CloseLootable = RS.LootingSystem_Storage.Remotes.CloseLootable
}

local accessing = {}
local initialized = {}

local function generateRandomLootableData()
    
end

remotes.OpenLootable.OnServerEvent:Connect(function(player: Player, taggedInstance: Instance, tag: string)  

    table.insert(accessing, player)
    if not table.find(initialized, taggedInstance) then
        table.insert(initialized, taggedInstance )
    end

    local hingeConstraint = if tag == "SingleHingeLootable" then taggedInstance:FindFirstChildWhichIsA("HingeConstraint", true) else nil
    if hingeConstraint then
        hingeConstraint.AngularSpeed = math.huge
        hingeConstraint.ServoMaxTorque = math.huge 
    end

    local reqModule = TAGS[tag]
    if reqModule then
        reqModule.onOpen_server(hingeConstraint)
    else
        warn(`Couldn't find required module with tag of {tag}`)
    end
end)

remotes.CloseLootable.OnServerEvent:Connect(function(player: Player, taggedInstance: Instance, tag: string)  

    table.remove(accessing, table.find(accessing, player))

    local hingeConstraint = if tag == "SingleHingeLootable" then taggedInstance:FindFirstChildWhichIsA("HingeConstraint", true) else nil
    if hingeConstraint then
        hingeConstraint.AngularSpeed = math.huge
        hingeConstraint.ServoMaxTorque = math.huge 
    end

    if #accessing ~= 0 then
        warn("Player's are still accessing this lootable, so Lootable's onClosed_server function will not run")
        return
    end

    local reqModule = TAGS[tag]
    if reqModule then
        reqModule.onClose_server(hingeConstraint)
    else
        warn(`Couldn't find required module with tag of {tag}`)
    end
end)
