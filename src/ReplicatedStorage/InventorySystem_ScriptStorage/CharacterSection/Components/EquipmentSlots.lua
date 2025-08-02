local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)

local ScriptStorage = game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage
local initData = require(ScriptStorage.CharacterSection.Components.EquipmentInitData)
local Type_Equipment = require(ScriptStorage.CharacterSection.Components.Type_Equipment)
local Slot = require(ScriptStorage.Components.Slot.Slot)


local EquipmentSlots = {}

function EquipmentSlots.init()
    for key, v in initData do
        Type_Equipment.typeCheck(key)
        local slot: Slot.SlotObject
        slot = Slot.new("Wearable", key:: Type_Equipment.EquipmentCategory)
        Slot.wearableCategoryToObjectMap[key] = slot
        slot._itself.AnchorPoint = Vector2.new(0.5, 0.5)
        slot._itself.ZIndex = 2
        slot._itself.LayoutOrder = v.LayoutOrder
        slot.ImageButton.Image = v.image
        slot.ImageButton.Rotation = 0
        slot.ImageButton.Visible = true
        slot._itself.Name = key
        slot._itself.Parent = References_Inventory.CharacterEquipmentSlots

        -- For if you want the lines conecting the slots to their corresponding body parts
        -------
        -- v.circle = circle:Clone()
        -- v.circle.Visible = true
        -- v.circle.Parent = wearableGuiInstances
        -- v.line = line:Clone()
        -- v.line.Visible = true
        -- v.line.Parent = wearableGuiInstances
    end
end

return EquipmentSlots