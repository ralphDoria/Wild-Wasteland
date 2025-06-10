-- This file had to be created because both Slot and Hover need to have access to SlotType,
-- but if I were to store this type in the Slot file as it was originally, there would 
-- be a circular dependency error.

local WearableCategory = require("./WearableCategory")

export type SlotState = "Idle" | "BeingSwapped" | "Dragging" | "Emptying" | "Filling" | "Destroying"

export type SlotType = {
    State: SlotState,
    _itself : Frame,
    _isEmpty : boolean,
    WearableCategory: WearableCategory.WearableCategoryType?, 
    InnerFrame : Frame,
    ImageButton : ImageButton,
    ActionIndicator : ImageLabel,
    HotbarNumber : TextLabel,
    Quantity : TextLabel,
    tool : Tool?,
    connections : {[string]: RBXScriptConnection}
}

return nil