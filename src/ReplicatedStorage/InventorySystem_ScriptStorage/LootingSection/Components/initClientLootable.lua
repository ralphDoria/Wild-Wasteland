local RS = game:GetService("ReplicatedStorage")
local References_Inventory_Client = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local InventoryScriptStorage = RS.RojoManaged_RS.InventorySystem_ScriptStorage
local StandardLootHPPManager = require(InventoryScriptStorage.LootingSection.Components.StandardLootHPPManager)
local LootGuiManager = require(InventoryScriptStorage.LootingSection.Components.LootGuiManager)
local InventoryToggle = require(InventoryScriptStorage.Components.InventoryToggle)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)
local Promise = require(RS.Packages.Promise)

local LootingSystem_Storage = References_Inventory_Client.ReplicatedStorage.LootingSystem_Storage
local rfn: {[string] : RemoteFunction} = {
    GetChangeReplicatorRemote = LootingSystem_Storage.Remotes.GetChangeReplicatorRemote
}

local function getDistanceBetween2Points(point1: Vector3, point2: Vector3)
    return math.abs( (point1-point2).Magnitude )
end

local function getPrimaryPart(lootable: Tool | Model)
    while lootable.PrimaryPart == nil do
        warn(`{lootable}'s PrimaryPart is nil, but may just be loading in. Did you make sure to set it?`)
        task.wait()
    end 
    return lootable.PrimaryPart   
end

local function initClientLootable(lootable: Tool | Model): (ProximityPrompt, Highlight)
    local changeReplicator: RemoteEvent? = rfn.GetChangeReplicatorRemote:InvokeServer(lootable)
    local onLootDataChanged: RBXScriptConnection?

    local primaryPart = getPrimaryPart(lootable)

    local hppManagerObject = StandardLootHPPManager.new(lootable, primaryPart, 
        function(pp: ProximityPrompt)  
            InventoryToggle.ChangeForm("LootingForm")

            LootActions.GetData(lootable)
                :andThen(function(filledSlotsData: Types_LootSystem.StandardFilledSlotsData)
                    LootGuiManager.RenderData(lootable, filledSlotsData)
                    if changeReplicator then
                        onLootDataChanged = changeReplicator.OnClientEvent:Connect(function(dataChangeRequest: Types_LootSystem.StandardDataChangeRequest | Types_LootSystem.CorpseDataChangeRequest)  
                            warn("received changeReplicator fire signal")
                            LootGuiManager.replaceSlot(dataChangeRequest)
                        end)
                    else
                        warn("Change replicator came back nil because taggedInstance was deregistered")
                        return
                    end
                    
                end)
                :catch(function(err)
                    warn(err)
                end
            )

            local promises = {
                closedAreaClicked = nil,
                onInvenotryFormChanged = nil,
                onExceededAccessDistance = nil
            }

            promises.closedAreaClicked = Promise.new(function(resolve, reject, onCancel)
                local onClosedAreaClicked: RBXScriptConnection? 
                onClosedAreaClicked = InventoryToggle.connectOnCloseAreaClicked(function()  
                    InventoryToggle.ChangeForm("Closed")
                    if onClosedAreaClicked then
                        onClosedAreaClicked:Disconnect() 
                    end

                    InventoryToggle.ChangeForm("Closed")

                    local promisesToCancel = table.clone(promises)
                    promisesToCancel.closedAreaClicked = nil
                    resolve(promisesToCancel)
                end)

                onCancel(function()
                    -- warn("Cancelling promise.closedAreaClicked")
                    if onClosedAreaClicked then
                        onClosedAreaClicked:Disconnect()
                    end
                end)
            end)

            promises.onExceededAccessDistance = Promise.new(function(resolve, reject, onCancel)

                local plr = game:GetService("Players").LocalPlayer
                local char = plr.Character or plr.Character:Wait()
                local hrp = char:WaitForChild("HumanoidRootPart")

                References_Inventory_Client.RunService:BindToRenderStep("DistanceCheckFromLootable", 2000, function(delta: number)  
                    if primaryPart and hrp then
                        local distance = getDistanceBetween2Points(primaryPart.Position, hrp.Position)
                        if distance > 5 then
                            References_Inventory_Client.RunService:UnbindFromRenderStep("DistanceCheckFromLootable")
                            InventoryToggle.ChangeForm("Closed")

                            local promisesToCancel = table.clone(promises)
                            promisesToCancel.onExceededAccessDistance = nil
                            resolve(promisesToCancel)
                        end
                    else
                        warn(`PrimaryPart ({primaryPart}) or HumanoidRootPart ({hrp}) is nil, so distance check cannot be done.`)
                    end
                end)

                onCancel(function()
                    -- warn("Cancelling promise.onExceededAccessDistance")
                    References_Inventory_Client.RunService:UnbindFromRenderStep("DistanceCheckFromLootable")
                end)
            end)

            promises.onInventoryFormChanged = Promise.new(function(resolve, reject, onCancel)
                local onInventoryFormChanged: RBXScriptConnection?
                onInventoryFormChanged = InventoryToggle.InventoryFormChanged:Once(function()
                    if onInventoryFormChanged then
                        onInventoryFormChanged:Disconnect()
                    end
                    local promisesToCancel = table.clone(promises)
                    promisesToCancel.onInvenotryFormChanged = nil
                    resolve(promisesToCancel)
                end)

                onCancel(function()
                    warn("Cancelling promise.onInventoryFormChanged")
                    if onInventoryFormChanged then
                        onInventoryFormChanged:Disconnect()
                    end
                end)
            end)

            Promise.race(
                {
                    promises.closedAreaClicked, -- resolves with case 1
                    promises.onExceededAccessDistance, -- resolves with case 2
                    promises.onInventoryFormChanged -- resolves with case 3
                }
            ):andThen(function(promisesToCancel)
                for _, v in promisesToCancel do
                    v:cancel()
                end
                LootGuiManager.StopRendering()
                if onLootDataChanged then
                    onLootDataChanged:Disconnect()
                    onLootDataChanged = nil                        
                end
                pp.Enabled = true
            end):catch(function(err)
                warn(tostring(err))
            end)
        end
    )

    return hppManagerObject.pp, hppManagerObject.highlight
end

return initClientLootable