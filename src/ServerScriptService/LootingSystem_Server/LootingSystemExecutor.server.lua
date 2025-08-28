local SSS = game:GetService("ServerScriptService")
local LootDataService = require(SSS.RojoManaged_SSS.LootingSystem_Server.Services.LootDataService)
LootDataService.init()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LootingSystem_Storage = ReplicatedStorage.LootingSystem_Storage
local remotes = {
    ToggleWornWearableAccessory = LootingSystem_Storage.Remotes.ToggleWornWearableAccessory:: RemoteEvent,
}

remotes.ToggleWornWearableAccessory.OnServerEvent:Connect(function(player: Player, toggle: boolean, corpseCharacter: Model, originalAccessory: Accessory)  
    if toggle then
            local clone: Accessory = originalAccessory:Clone()
            clone.Name = originalAccessory.Name .. "Worn"
            clone.Parent = corpseCharacter
    else
        local accessory = corpseCharacter:FindFirstChild(originalAccessory.Name  .. "Worn", true)
        if accessory then
            accessory:Destroy()
        else
            warn(originalAccessory.Name .. "Worn" .. " not found, can't be destroyed")
        end
    end
end)
-- local remotes = {
--     OpenLootable = RS.LootingSystem_Storage.Remotes.OpenLootable,
--     CloseLootable = RS.LootingSystem_Storage.Remotes.CloseLootable
-- }

-- local accessing = {}
-- local initialized = {}

-- local function generateRandomLootableData()
     
-- end

-- remotes.OpenLootable.OnServerEvent:Connect(function(player: Player, taggedInstance: Instance, tag: string)  

--     table.insert(accessing, player)
--     if not table.find(initialized, taggedInstance) then
--         table.insert(initialized, taggedInstance )
--     end

--     local hingeConstraint = if tag == "SingleHingeLootable" then taggedInstance:FindFirstChildWhichIsA("HingeConstraint", true) else nil
--     if hingeConstraint then
--         hingeConstraint.AngularSpeed = math.huge
--         hingeConstraint.ServoMaxTorque = math.huge 
--     end

--     local reqModule = TAGS[tag]
--     if reqModule then
--         reqModule.onOpen_server(hingeConstraint)
--     else
--         warn(`Couldn't find required module with tag of {tag}`)
--     end
-- end)

-- remotes.CloseLootable.OnServerEvent:Connect(function(player: Player, taggedInstance: Instance, tag: string)  

--     table.remove(accessing, table.find(accessing, player))

--     local hingeConstraint = if tag == "SingleHingeLootable" then taggedInstance:FindFirstChildWhichIsA("HingeConstraint", true) else nil
--     if hingeConstraint then
--         hingeConstraint.AngularSpeed = math.huge
--         hingeConstraint.ServoMaxTorque = math.huge 
--     end

--     if #accessing ~= 0 then
--         warn("Player's are still accessing this lootable, so Lootable's onClosed_server function will not run")
--         return
--     end

--     local reqModule = TAGS[tag]
--     if reqModule then
--         reqModule.onClose_server(hingeConstraint)
--     else
--         warn(`Couldn't find required module with tag of {tag}`)
--     end
-- end)