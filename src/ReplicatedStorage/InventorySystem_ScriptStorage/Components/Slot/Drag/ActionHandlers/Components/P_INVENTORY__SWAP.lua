local ReplicatedStorage = game:GetService("ReplicatedStorage")
local References_Inventory = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.References_Inventory_Client)
local types_and_enums = require(ReplicatedStorage.RojoManaged_RS.InventorySystem_ScriptStorage.Components.Slot.Drag.types_and_enums)

-- helper function to swap two slot's positional attributes within inventory
local function P_INVENTORY__SWAP(s1Data: types_and_enums.SlotData, s2Data: types_and_enums.SlotData)
    local slotObject1 = s1Data.slotObject
    local slotObject2 = s2Data.slotObject

    local slotInstance1 = slotObject1._itself
    local slotInstance2 = slotObject2._itself

    if slotInstance2.Parent ~= slotInstance1.Parent then
        local s2_savedParent = slotInstance2.Parent
        slotInstance2.Parent = slotInstance1.Parent
        slotInstance1.Parent = s2_savedParent
    end

    local s2LO = slotInstance2.LayoutOrder
    local s1LO = slotInstance1.LayoutOrder
    slotInstance2.LayoutOrder = s1LO
    slotObject2.HotbarNumber.Text = tostring(s1LO)
    slotInstance1.LayoutOrder = s2LO
    slotObject1.HotbarNumber.Text = tostring(s2LO)
    if slotInstance1.Parent == References_Inventory.Hotbar then
        slotObject1.HotbarNumber.Visible = true
    else 
        slotObject1.HotbarNumber.Visible = false
    end
    if slotInstance2.Parent == References_Inventory.Hotbar then
        slotObject2.HotbarNumber.Visible = true
    else
        slotObject2.HotbarNumber.Visible = false
    end
end

return P_INVENTORY__SWAP