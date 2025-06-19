-- This file had to be created because both Slot and Hover need to have access to SlotType,
-- but if I were to store this type in the Slot file as it was originally, there would 
-- be a circular dependency error.

local Type_Equipment = require(game:GetService("ReplicatedStorage").RojoManaged_RS.InventorySystem_ScriptStorage.CharacterSection.Components.Type_Equipment)

export type SlotState = "Idle" | "BeingSwapped" | "Dragging" | "Emptying" | "Filling" | "Destroying"

export type SlotObject = {
    State: SlotState,
    _itself : Frame,
    _isEmpty : boolean,
    WearableCategory: Type_Equipment.EquipmentCategory?, 
    InnerFrame : Frame,
    ImageButton : ImageButton,
    ActionIndicator : ImageLabel,
    HotbarNumber : TextLabel,
    Quantity : TextLabel,
    tool : Tool?,
    connections : {[string]: RBXScriptConnection},
}

return nil