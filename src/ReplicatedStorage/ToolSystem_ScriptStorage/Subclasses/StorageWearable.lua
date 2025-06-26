local Wearable = require("./Wearable")
local SlotGroup = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.SlotGroup)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}
type StorageWearableObject = Wearable.WearableType & {
    Space: number, -- number of storage slots it'll the wearer
    ItemGroup: SlotGroup.object?,
    objValue: ObjectValue,
    lootPrompt: ProximityPrompt,
    isUpdating: boolean
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local initializeClientSideStandardLootable = require(InventoryScriptStorage.LootingSection.Components.initializeClientSideStandardLootable)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)

local StorageWearable = {}

function StorageWearable.new(tool: Tool, humanoid: Humanoid): StorageWearableObject
    local self = Wearable.new(tool, humanoid)
    self.Space = tool:GetAttribute("Space")

    self.objValue = Instance.new("ObjectValue")
    self.objValue.Name = "AssociatedItemGroup"
    self.objValue.Parent = tool
    self.isUpdating = false

    StorageWearable._initialize(self)

    return self:: StorageWearableObject
end

function StorageWearable._initialize(self: StorageWearableObject)
    Wearable.initialize(
        self, 
        function() -- onWearing
            self.soundManager.playSound("Client", self.soundManager.Sounds[self.tool.Name].wear :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0)
        end,
        function() -- onUnwearing
            self.soundManager.playSound("Client", self.soundManager.Sounds[self.tool.Name].unwear :: Sound, self.tool:FindFirstChild("BodyAttach", true), 0.1)
        end,
        function() -- appyWornEffects 
            LootActions.GetData(self.tool)
                :andThen(function(lootData: Types_LootSystem.StandardLootableObject)
                    local slotGroup = SlotGroup.new(self.tool.Name, lootData.Space, lootData)
                    self.ItemGroup = slotGroup
                    self.objValue.Value = slotGroup._itself
                end)
                :catch(function(err)
                    warn(tostring(err))
                end)
        end, 
        function() -- removeWornEffects
            if self.ItemGroup then
                -- for _, v in self.ItemGroup.ItemSlots do
                --     if not v._isEmpty then
                --         print(`dropping {v.tool}`)
                --         bindables.DropToolBindable:Fire(v.tool)
                --     end
                -- end
                self.ItemGroup._itself.Visible = false
                self.isUpdating = true
                LootActions.updateStorageWearableLootData(self.tool, self.ItemGroup)
                    :andThen(function()
                        SlotGroup.Destroy(self.ItemGroup)
                        self.objValue.Value = nil
                    end)
                    :catch(function(err)
                        warn(err)
                    end):finally(function()
                        self.isUpdating = false
                    end)
            end
        end
    )

    local pickUpPrompt = self.ToolHighlightAndProxPromptManager.pp
    local lootPrompt: ProximityPrompt, lootHighlight: Highlight = initializeClientSideStandardLootable(self.tool)
    lootHighlight:Destroy()

    lootPrompt.UIOffset = Vector2.new(0, -30)
    lootPrompt.KeyboardKeyCode = Enum.KeyCode.F
    lootPrompt.ObjectText = ""
    lootPrompt.Enabled = false
    lootPrompt.MaxActivationDistance = pickUpPrompt.MaxActivationDistance
    self.connections.showLootPrompt = pickUpPrompt.PromptShown:Connect(function()  
        lootPrompt.Enabled = true
    end)
    self.connections.hideLootPrompt = pickUpPrompt.PromptShown:Connect(function()  
        lootPrompt.Enabled = false
    end)
    self.lootPrompt = lootPrompt
end

function StorageWearable.Destroy()
end

return StorageWearable