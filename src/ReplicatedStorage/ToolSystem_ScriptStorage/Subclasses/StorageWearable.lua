local Wearable = require("./Wearable")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SlotGroup = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.SlotGroup)
local player = game:GetService("Players").LocalPlayer
local ToolSystem_Storage = ReplicatedStorage:FindFirstChild("ToolSystem_Storage", true)
local bindables = {
    DropToolBindable = ToolSystem_Storage.Shared.Bindables.DropToolBindable,
}
type StorageWearableObject = Wearable.WearableType & {
    Space: number, -- number of storage slots it'll the wearer
    slotGroup: SlotGroup.object?,
    associatedSlotGroup: ObjectValue,
    lootPrompt: ProximityPrompt,
    isUpdating: boolean
}

local InventoryScriptStorage = ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage
local initializeClientSideStandardLootable = require(InventoryScriptStorage.LootingSection.Components.initializeClientSideStandardLootable)
local LootActions = require(InventoryScriptStorage.LootingSection.Components.LootActions)
local Types_LootSystem = require(InventoryScriptStorage.LootingSection.Components.Types_LootSystem)
local LootGuiManager = require(InventoryScriptStorage.LootingSection.Components.LootGuiManager)

local StorageWearable = {}

function StorageWearable.new(tool: Tool, humanoid: Humanoid): StorageWearableObject
    local self = Wearable.new(tool, humanoid)
    self.Space = tool:GetAttribute("Space")

    local associatedSlotGroup = Instance.new("ObjectValue")
    self.associatedSlotGroup = associatedSlotGroup
    associatedSlotGroup.Name = "AssociatedItemGroup"
    associatedSlotGroup.Parent = tool
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
                :andThen(function(filledSlotsData: Types_LootSystem.FilledSlotsData)
                    local slotGroup = SlotGroup.new(self.tool.Name, self.Space, filledSlotsData)
                    self.slotGroup = slotGroup
                    self.associatedSlotGroup.Value = slotGroup._itself
                end)
                :catch(function(err)
                    warn(tostring(err))
                end)
        end, 
        function() -- removeWornEffects
            if self.slotGroup then
                self.slotGroup._itself.Visible = false
                self.isUpdating = true
                LootActions.updateStorageWearableLootData(self.tool, self.slotGroup)
                    :andThen(function()
                        SlotGroup.Destroy(self.slotGroup)
                        self.associatedSlotGroup.Value = nil
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
    lootPrompt.ObjectText = ""
    lootPrompt.Enabled = false
    lootPrompt.MaxActivationDistance = pickUpPrompt.MaxActivationDistance
    self.connections.showLootPrompt = pickUpPrompt.PromptShown:Connect(function()  
        lootPrompt.Enabled = true
    end)
    self.connections.hideLootPrompt = pickUpPrompt.PromptShown:Connect(function()  
        lootPrompt.Enabled = false
    end)
    local zipperOpen: Sound = self.soundManager.Sounds[self.tool.Name].zipperOpen
    local zipperClose: Sound = self.soundManager.Sounds[self.tool.Name].zipperClose
    self.connections.hidePickupPrompt = pickUpPrompt.PromptButtonHoldBegan:Connect(function()
        lootPrompt.Enabled = false
    end)
    self.connections.oogabooga = pickUpPrompt.PromptButtonHoldEnded:Connect(function(a0: Player)  
        lootPrompt.Enabled = true
    end)
    self.connections.zipperOpen = lootPrompt.PromptButtonHoldBegan:Connect(function()
        zipperOpen:Play()
        zipperClose:Stop()
    end)
    self.connections.zipperClose = lootPrompt.PromptButtonHoldEnded:Connect(function()
        zipperOpen:Stop()
    end)

    local WornItems = player.Backpack:WaitForChild("WornItems"):: Folder
    local wearableCategoryFolder = WornItems[self.WearableCategory]:: Folder
    local isWearingBackpackAlready: boolean
    local isEmpty_server: boolean

    local function updatePromptText()
        if not isEmpty_server and isWearingBackpackAlready then
            pickUpPrompt.ActionText = "Swap Backpacks"
        elseif not isEmpty_server and not isWearingBackpackAlready then
            pickUpPrompt.ActionText = "Put On"
        elseif isEmpty_server then
            pickUpPrompt.ActionText = "Pick Up"
        end
    end

    self.connections.onItemWorn = wearableCategoryFolder.ChildAdded:Connect(function(tool: Tool)  
        assert(tool:IsA("Tool"), "Only tools are supposed to be inserted here")
        isWearingBackpackAlready = true

        updatePromptText()
    end)

    self.connections.onItemUnworn = wearableCategoryFolder.ChildRemoved:Connect(function(tool: Tool)  
        assert(tool:IsA("Tool"), "Only tools are supposed to be inserted here")
        isWearingBackpackAlready = false

        updatePromptText()
    end)

    self.connections.onIsEmptyChanged = self.tool:GetAttributeChangedSignal("isEmpty_server"):Connect(function()  
        isEmpty_server = self.tool:GetAttribute("isEmpty_server"):: boolean
        updatePromptText()
    end)
    
    LootGuiManager.renderChanged:Connect(function(lootableInstance: (Model | Tool)?)
        print(self.State)
        if self.tool.Parent == workspace then
            print(`render changed to {lootableInstance}`)
            pickUpPrompt.Enabled =  lootableInstance == self.associatedSlotGroup.Value
        end

        updatePromptText()
    end)
    self.lootPrompt = lootPrompt
end

function StorageWearable.Destroy()
end

return StorageWearable