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
        v.slot = Slot.new("Wearable", key:: Type_Equipment.EquipmentCategory)
        Slot.wearableCategoryToObjectMap[key] = v.slot
        v.slot._itself.AnchorPoint = Vector2.new(0.5, 0.5)
        v.slot._itself.ZIndex = 2
        v.slot._itself.LayoutOrder = v.LayoutOrder
        v.slot.ImageButton.Image = v.image
        v.slot.ImageButton.Rotation = 0
        v.slot.ImageButton.Visible = true
        v.slot._itself.Name = key
        v.slot._itself.Parent = References_Inventory.CharacterEquipmentSlots

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