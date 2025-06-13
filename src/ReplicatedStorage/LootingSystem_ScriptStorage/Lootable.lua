local HighlightAndProximityPromptManager = require("./HighlightAndProximityPromptManager")
local LootingGuiManager = require("./LootingGuiManager")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local InventorySystem = require(RS.RojoManaged_RS.InventorySystem_ScriptStorage.InventorySystem)
local Promise = require(RS.Packages.Promise)

-- local remotes = {
--     onTriggered = 
-- }

export type LootableObject = {
    model: Model,
    hppManager: HighlightAndProximityPromptManager.HighlightAndProximityPromptManagerObject,
    onOpen: () -> (),
    onClose: () -> (),
    Connections: {RBXScriptConnection}
}
local Lootable = {}

function Lootable.new(instance: Instance, ppParent, onOpen: () -> (), onClose: () -> ())
    local self: LootableObject = {
        model = instance,
        hppManager = HighlightAndProximityPromptManager.new(instance, ppParent),
        onOpen = onOpen,
        onClose = onClose,
        Connections = {}
    }

    Lootable._initialize(self)

    return self
end

function Lootable._onOpen(self: LootableObject)
    self.hppManager.pp.Enabled = false
    self.onOpen()
    LootingGuiManager.toggle(true, self.model.Name)
end

function Lootable._onClose(self: LootableObject)
    self.hppManager.pp.Enabled = true
    self.onClose()
    LootingGuiManager.toggle(false)
end

local function getDistanceBetween2Points(point1: Vector3, point2: Vector3)
    return math.abs( (point1-point2).Magnitude )
end

function Lootable._initialize(self: LootableObject)
    table.insert(
        self.Connections,
        self.hppManager.pp.Triggered:Connect(function()
            
            InventorySystem.toggleBinds(false)
            Lootable._onOpen(self)

            local plr = game:GetService("Players").LocalPlayer
            local char = plr.Character or plr.Character:Wait()
            local hrp = char:WaitForChild("HumanoidRootPart")

            local function foo()
                Lootable._onClose(self)
                InventorySystem.toggleBinds(true)
            end

            local clickedOutsideConnection: RBXScriptConnection
            Promise.race(
                {
                    Promise.new(function(resolve, reject)
                        clickedOutsideConnection = LootingGuiManager.ClickedOutside:Once(function()  
                            foo()
                            resolve()
                        end)
                    end),
                    Promise.new(function(resolve, reject)
                        RunService:BindToRenderStep("DistanceCheckFromLootable", 2000, function(delta: number)  
                            local primaryPart = self.model.PrimaryPart
                            if primaryPart and hrp then
                                local distance = getDistanceBetween2Points(primaryPart.Position, hrp.Position)
                                if distance > 5 then
                                    RunService:UnbindFromRenderStep("DistanceCheckFromLootable")
                                    foo()
                                    resolve()
                                end
                            else
                                warn(`PrimaryPart ({primaryPart}) or HumanoidRootPart ({hrp}) is nil, so distnace check cannot be done.`)
                            end
                        end)
                    end)
                }
            ):andThen(function()
                if clickedOutsideConnection then
                    clickedOutsideConnection:Disconnect()
                end
                RunService:UnbindFromRenderStep("DistanceCheckFromLootable")
            end):catch(function(err)
                warn(tostring(err))
            end)

        end)
    )
end

function Lootable.Destroy(self: LootableObject)
    
end

return Lootable