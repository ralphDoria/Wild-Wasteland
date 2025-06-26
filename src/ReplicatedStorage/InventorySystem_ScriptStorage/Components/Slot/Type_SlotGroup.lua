local Type_Slot = require("./Type_Slot")

export type state = "Empty" | "Filled"

export type object = {
    _itself: Frame,
    State: state,
    Name: string,
    Space: number,
    ItemSlots: {[Frame]: Type_Slot.SlotObject},
    ItemsFrame: Frame,
    Connections: {RBXScriptConnection}
}

return nil