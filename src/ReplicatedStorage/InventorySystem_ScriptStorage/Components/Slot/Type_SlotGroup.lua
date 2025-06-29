local Type_Slot = require("./Type_Slot")

export type state = "Empty" | "Filled"

export type object = {
    _itself: Frame,
    State: state,
    Name: string,
    Space: number,
    slotInstanceToObjectMap: {[Frame]: Type_Slot.SlotObject},
    _numberOfFilledSlots: number,
    SlotsFrame: Frame,
    Connections: {RBXScriptConnection}
}

return nil